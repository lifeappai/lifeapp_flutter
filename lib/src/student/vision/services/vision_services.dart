import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vision_video.dart';
import '../../../utils/storage_utils.dart';
import '../../../common/helper/string_helper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class VisionAPIService {
  static const String baseUrl = 'https://api.life-lab.org/v3';
  static const int _requestTimeout = 15;

  Future<String?> _getAuthToken() async {
    try {
      final token = StorageUtil.getString(StringHelper.token);
      if (token.isEmpty) {
        debugPrint('❌ No auth token found');
        return null;
      }
      debugPrint('🔑 Auth token retrieved');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _makeRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _getHeaders(token);

    debugPrint('🔄 $method $uri');
    if (body != null) debugPrint('📤 Body: ${json.encode(body)}');

    try {
      final response = await (method.toUpperCase() == 'GET'
          ? http.get(uri, headers: headers)
          : http.post(uri, headers: headers, body: json.encode(body)))
          .timeout(const Duration(seconds: _requestTimeout));

      debugPrint('📡 Status: ${response.statusCode}');
      if (response.body.isNotEmpty) debugPrint('📡 Response: ${response.body}');
      return response;
    } catch (e) {
      debugPrint('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic>? _parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      debugPrint('❌ Empty response body');
      return null;
    }
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      debugPrint('❌ Response is not a JSON object');
      return null;
    } catch (e) {
      debugPrint('❌ JSON parse error: $e');
      return null;
    }
  }

  void _handleErrorResponse(http.Response response) {
    final responseData = _parseResponse(response) ?? {};
    final errorMessage = responseData['message']?.toString() ?? 'Unknown error';

    if (response.statusCode == 401) {
      debugPrint('🔐 Authentication failed');
      throw Exception('Please log in again');
    }
    if (response.statusCode == 400 && errorMessage.contains('not found')) {
      throw VisionNotFoundException(errorMessage);
    }
    if (response.statusCode == 400 && errorMessage.contains('inactive')) {
      throw VisionInactiveException(errorMessage);
    }
    throw Exception('Error ${response.statusCode}: $errorMessage');
  }

  Future<Map<String, dynamic>?> getVisionDetails(String visionId) async {
    try {
      debugPrint('🔍 Fetching vision details: $visionId');
      final endpoints = [
        '/vision/details?vision_id=$visionId',
        '/vision/info?vision_id=$visionId',
        '/vision/$visionId',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _makeRequest('GET', endpoint);
          if (response.statusCode == 200) {
            final data = _parseResponse(response);
            if (data != null) {
              debugPrint('✅ Details retrieved from $endpoint');
              return data;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed $endpoint: $e');
        }
      }
      debugPrint('❌ No vision details found');
      return null;
    } catch (e) {
      debugPrint('💥 Error in getVisionDetails: $e');
      return null;
    }
  }

  Future<List<VisionVideo>> getVisionVideos(String subjectId, String levelId) async {
    try {
      debugPrint('🔄 Fetching videos for subject: $subjectId, $levelId');
      final response = await _makeRequest(
          'GET', '/vision/list?la_subject_id=$subjectId&la_level_id=$levelId');

      if (response.statusCode != 200) _handleErrorResponse(response);

      final data = _parseResponse(response);
      if (data == null || data['data'] == null) {
        debugPrint('❌ Invalid video response');
        return [];
      }

      final videos = _parseVideoData(data['data']);
      debugPrint('✅ Parsed ${videos.length} videos');
      return videos;
    } catch (e) {
      debugPrint('💥 Error in getVisionVideos: $e');
      return [];
    }
  }

  List<VisionVideo> _parseVideoData(dynamic data) {
    List<dynamic> videoData = [];
    if (data is List) {
      videoData = data;
    } else if (data is Map<String, dynamic>) {
      if (data['visions'] is List) {
        videoData = data['visions'] as List;
      } else if (data['visions'] is Map && data['visions']['data'] is List) {
        videoData = data['visions']['data'] as List;
      } else if (data['videos'] is List) {
        videoData = data['videos'] as List;
      } else if (data['data'] is List) {
        videoData = data['data'] as List;
      }
    }

    if (videoData.isEmpty) {
      debugPrint('⚠️ No videos found');
      return [];
    }

    return videoData
        .whereType<Map<String, dynamic>>()
        .map((item) {
      try {
        return VisionVideo.fromJson(item);
      } catch (e) {
        debugPrint('⚠️ Error parsing video: $e');
        return null;
      }
    })
        .whereType<VisionVideo>()
        .toList();
  }

  Future<Map<String, dynamic>> getVisionQuestions(String visionId) async {
    try {
      debugPrint('🔄 Fetching questions for vision: $visionId');
      final response = await _makeRequest('GET', '/vision/$visionId/questions');

      if (response.statusCode != 200) _handleErrorResponse(response);
      final data = _parseResponse(response);

      if (data == null || data['data'] == null) {
        throw Exception('Failed to load questions');
      }

      final raw = data['data'];

      List mcqQuestions = [];
      Map<String, dynamic>? descriptiveQuestion;
      Map<String, dynamic>? imageQuestion;

      if (raw is List) {
        for (var q in raw) {
          switch (q['question_type']) {
            case 'mcq':
              mcqQuestions.add(q);
              break;
            case 'reflection':
              descriptiveQuestion = q;
              break;
            case 'image':
              imageQuestion = q;
              break;
          }
        }
      } else if (raw is Map) {
        mcqQuestions = raw['mcq_questions'] ?? [];
        descriptiveQuestion = raw['descriptive_question'];
        imageQuestion = raw['image_question'];
      }

      return {
        'mcq_questions': mcqQuestions,
        'descriptive_question': descriptiveQuestion,
        'image_question': imageQuestion,
        'message': data['message'] ?? 'Questions loaded',
      };
    } catch (e) {
      debugPrint('💥 Error in getVisionQuestions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> submitVideoAnswers(
      String visionId,
      List<Map<String, dynamic>> answers,
      ) async {
    try {
      debugPrint('🔄 Submitting answers for vision: $visionId');

      final cleanAnswers = _cleanAndValidateAnswers(answers);
      if (cleanAnswers.isEmpty) {
        debugPrint('❌ No valid answers');
        return {
          'submission_successful': false,
          'error': 'No valid answers provided',
          'submitted_at': DateTime.now().toIso8601String(),
        };
      }

      String formatDuration(Duration d) {
        String two(int n) => n.toString().padLeft(2, '0');
        return "${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}";
      }
      const duration = Duration(seconds: 75);
      final timing = formatDuration(duration);

      // Submit MCQ answers
      if (cleanAnswers.any((a) => a['type'] == 'mcq')) {
        final mcqAnswers = cleanAnswers
            .where((a) => a['type'] == 'mcq')
            .map((a) => {
          'question_id': a['id'],
          'answer_option': a['answer'].toString(),
        })
            .toList();

        final body = {
          'vision_id': int.tryParse(visionId),
          'timing': timing,
          'answer_type': 'option',
          'answers': mcqAnswers,
        };

        final response = await _makeRequest('POST', '/vision/complete', body: body);
        if (response.statusCode != 200 && response.statusCode != 201) {
          _handleErrorResponse(response);
          return null;
        }
      }

      // Submit Descriptive answers
      if (cleanAnswers.any((a) => a['type'] == 'descriptive')) {
        for (final ans in cleanAnswers.where((a) => a['type'] == 'descriptive')) {
          final body = {
            'vision_id': int.tryParse(visionId),
            'timing': timing,
            'answer_type': 'text',
            'question_id': ans['id'],
            'answer_text': ans['answer'].toString(),
          };
          final response = await _makeRequest('POST', '/vision/complete', body: body);
          if (response.statusCode != 200 && response.statusCode != 201) {
            _handleErrorResponse(response);
            return null;
          }
        }
      }

      // Submit Image answers
      if (cleanAnswers.any((a) => a['type'] == 'image')) {
        for (final ans in cleanAnswers.where((a) => a['type'] == 'image')) {
          try {
            debugPrint('📸 Uploading image: $ans');

            // Check file size first
            final file = File(ans['image_path']);
            final sizeInMB = file.lengthSync() / (1024 * 1024);
            if (sizeInMB > 5) {
              debugPrint('❌ File too large: ${sizeInMB.toStringAsFixed(1)}MB');
              return {
                'submission_successful': false,
                'error': 'Image file too large (${sizeInMB.toStringAsFixed(1)}MB). Maximum size is 5MB.',
              };
            }

            // Compress the image
            debugPrint('🔄 Compressing image...');
            final compressedFile = await FlutterImageCompress.compressAndGetFile(
              ans['image_path'],
              '${(await getTemporaryDirectory()).path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
              quality: 70,
              minWidth: 1024,
              minHeight: 1024,
            );

            if (compressedFile == null) {
              debugPrint('❌ Compression failed');
              throw Exception('Image compression failed');
            }

            final token = await _getAuthToken();
            if (token == null) throw Exception('No authentication token');

            final uri = Uri.parse('https://api.life-lab.org/v3/vision/complete');
            final request = http.MultipartRequest('POST', uri)
              ..fields['vision_id'] = visionId
              ..fields['timing'] = timing
              ..fields['answer_type'] = 'image'
              ..fields['question_id'] = ans['id'].toString()
              ..fields['description'] = ans['answer'] ?? ''
              ..headers.addAll(_getHeaders(token));

            try {
              request.files.add(await http.MultipartFile.fromPath(
                'media',
                compressedFile.path,
              ));
            } catch (e) {
              debugPrint('❌ File error: $e');
              return {
                'submission_successful': false,
                'error': 'Could not read image file.',
              };
            }

            debugPrint('🔼 Uploading compressed image');
            final streamed = await request.send();
            final response = await http.Response.fromStream(streamed);
            debugPrint('📤 Status: ${response.statusCode}');

            if (response.statusCode != 200 && response.statusCode != 201) {
              return {
                'submission_successful': false,
                'error': 'Image upload failed',
                'server_response': response.body,
                'submitted_at': DateTime.now().toIso8601String(),
              };
            }
          } catch (e) {
            debugPrint('❌ Exception: $e');
            return {
              'submission_successful': false,
              'error': 'Exception during image upload: $e',
            };
          }
        }
      }

      // Track vision completion with important properties
      MixpanelService.track("Vision Completed", properties: {
        "vision_id": visionId,
        "timestamp": DateTime.now().toIso8601String(),
        "answer_count": cleanAnswers.length,
        "submission_type": cleanAnswers.length == answers.length ? "full" : "partial",
        "has_mcq": cleanAnswers.any((a) => a['type'] == 'mcq'),
        "has_descriptive": cleanAnswers.any((a) => a['type'] == 'descriptive'),
        "has_image": cleanAnswers.any((a) => a['type'] == 'image'),
        "completion_time": timing,
      });

      debugPrint('✅ Vision submission completed successfully');

      return {
        'submission_successful': true,
        'message': 'All answers submitted successfully',
        'submitted_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('💥 Error submitting answers: $e');
      return {
        'submission_successful': false,
        'error': e.toString(),
        'submitted_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Map<String, dynamic> _calculateScoreSummary(List<dynamic> quizData) {
    int correctCount = 0;
    final results = quizData.map((item) {
      final isCorrect = item['is_correct'] == true;
      if (isCorrect) correctCount++;
      return {
        'question_id': item['question_id']?.toString(),
        'selected_answer': item['answer']?.toString(),
        'correct_answer': item['correct_answer']?.toString() ??
            item['correct_option']?.toString(),
        'is_correct': isCorrect,
      };
    }).toList();

    final total = quizData.length;
    final percentage = total > 0 ? (correctCount / total * 100) : 0.0;

    return {
      'total_questions': total,
      'correct_answers': correctCount,
      'incorrect_answers': total - correctCount,
      'percentage': percentage.round(),
      'passed': percentage >= 60,
      'question_results': results,
    };
  }

  Future<Map<String, dynamic>?> submitVideoAnswersAndGetResult(
      String visionId, List<Map<String, dynamic>> answers) async {
    try {
      debugPrint('🔄 Submitting and fetching result for vision: $visionId');
      final submission = await submitVideoAnswers(visionId, answers);

      if (submission == null || submission['submission_successful'] != true) {
        debugPrint('❌ Submission failed');
        return submission;
      }

      if (submission['quiz_result'] != null) {
        debugPrint('✅ Result from submission');
        return submission;
      }

      try {
        final result = await getQuizResult(visionId);
        debugPrint('✅ Quiz result retrieved');

        final scoreSummary = _calculateScoreSummary(
            result is List ? result : result['data'] ?? []);

        return {
          'submission_successful': true,
          'quiz_result': result,
          'score_summary': scoreSummary,
          'submitted_at': submission['submitted_at'],
        };
      } catch (e) {
        debugPrint('⚠️ Failed to fetch result: $e');
        return {
          'submission_successful': true,
          'result_pending': true,
          'message': 'Quiz submitted, results pending',
          'submitted_at': submission['submitted_at'],
        };
      }
    } catch (e) {
      debugPrint('💥 Error in submitVideoAnswersAndGetResult: $e');
      return {
        'submission_successful': false,
        'error': 'Failed to submit answers: $e',
      };
    }
  }

  List<Map<String, dynamic>> _cleanAndValidateAnswers(
      List<Map<String, dynamic>> answers) {
    final uniqueAnswers = <String, Map<String, dynamic>>{};

    for (final answer in answers) {
      final id = answer['id']?.toString();
      final value = answer['answer']?.toString().trim();

      if (id == null || value == null || value.isEmpty) {
        debugPrint('⚠️ Skipping invalid answer: $answer');
        continue;
      }

      final cleanedAnswer = {
        'id': id,
        'answer': value,
        'type': answer['type']?.toString() ?? 'mcq',
      };

      if (answer.containsKey('image_path') &&
          answer['image_path']?.toString().isNotEmpty == true) {
        cleanedAnswer['image_path'] = answer['image_path'].toString();
      }

      uniqueAnswers[id] = cleanedAnswer;
    }

    return uniqueAnswers.values.toList();
  }

  Future<Map<String, dynamic>> getQuizResult(String visionId) async {
    try {
      var visionID = int.tryParse(visionId);
      debugPrint('🔄 Fetching quiz result for vision: $visionID');

      final body = {
        'vision_id': int.tryParse(visionId),
      };
      final response =
      await _makeRequest('POST', '/vision/result', body: body);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        if (data == null || (data['data'] == null && data['status'] != 200)) {
          throw Exception('Invalid quiz result');
        }
        debugPrint('✅ Quiz result retrieved');
        return data['data'] ?? data;
      }
      _handleErrorResponse(response);
      throw Exception('Failed to fetch quiz result');
    } catch (e) {
      debugPrint('💥 Error in getQuizResult: $e');
      rethrow;
    }
  }

  Future<bool> skipQuiz(String visionId) async {
    try {
      debugPrint('🔄 Skipping quiz: $visionId');

      final response = await _makeRequest('POST', '/vision/skip',
          body: {'vision_id': visionId});

      if (response.statusCode == 200) {
        final data = _parseResponse(response) ?? {};
        debugPrint('✅ Quiz skipped');

        // Track vision skipped with important properties
        MixpanelService.track("Vision Skipped", properties: {
          "vision_id": visionId,
          "timestamp": DateTime.now().toIso8601String(),
          "skip_reason": "user_initiated", // Could be enhanced with more context
          "device_type": Platform.isAndroid ? "android" : Platform.isIOS ? "ios" : "other",
          "app_version": "1.0.0", // Should be replaced with actual version
        });

        return true;
      }
      _handleErrorResponse(response);
      return false;
    } catch (e) {
      debugPrint('💥 Error in skipQuiz: $e');
      return false;
    }
  }

  Future<bool> markQuizPending(String visionId) async {
    try {
      debugPrint('🔄 Marking quiz pending: $visionId');
      final response = await _makeRequest('POST', '/vision/pending',
          body: {'vision_id': visionId});

      if (response.statusCode == 200) {
        final data = _parseResponse(response) ?? {};
        debugPrint('✅ Quiz marked pending');
        return true;
      }
      _handleErrorResponse(response);
      return false;
    } catch (e) {
      debugPrint('💥 Error in markQuizPending: $e');
      return false;
    }
  }
}

class VisionNotFoundException implements Exception {
  final String message;
  VisionNotFoundException(this.message);
  @override
  String toString() => 'VisionNotFoundException: $message';
}

class VisionInactiveException implements Exception {
  final String message;
  VisionInactiveException(this.message);
  @override
  String toString() => 'VisionInactiveException: $message';
}