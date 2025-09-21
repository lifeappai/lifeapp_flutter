import 'package:flutter/material.dart';
import '../models/vision_model.dart';
import '../providers/vision_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class Answer {
  final String answerType; // 'mcq', 'text', 'image'
  final String answerText; // For text answers
  final String? selectedOption; // For MCQ
  final String? correctOption;
  final bool? isCorrect;
  final String? questionText;
  final String? imageUrl; // For image answers
  final String? description;

  Answer({
    required this.answerType,
    required this.answerText,
    this.selectedOption,
    this.correctOption,
    this.isCorrect,
    this.questionText,
    this.imageUrl,
    this.description,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerType: json['answer_type'] ?? '',
      answerText: json['answer_text'] ?? '',
      selectedOption: json['selected_option'],
      correctOption: json['correct_option'],
      isCorrect: json['is_correct'],
      questionText: json['question_text'],
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }
}
// Model for student submission
class StudentSubmission {
  final String id;
  final String studentName;
  final String studentAvatar;
  final SubmissionStatus status;
  final String? submissionDate;
  final String? submissionUrl;
  final String? feedback;
  final String? mobileno;
  final String? className;
  final String? section;
  final List<Answer> answers;


  StudentSubmission({
    required this.id,
    required this.studentName,
    required this.studentAvatar,
    required this.status,
    this.submissionDate,
    this.submissionUrl,
    this.feedback,
    this.mobileno,
    this.className,
    this.section,
    required this.answers,

    // this.answer,
    // this.question,

  });

  factory StudentSubmission.fromJson(Map<String, dynamic> json) {
    print('hel $json');
    String _cleanFirstPart(dynamic value) {
      if (value == null) return '';
      final str = value.toString();
      // Split by space or by " (" or just "("
      return str.split(RegExp(r'\s*\(')).first.trim();
    }

    return StudentSubmission(
      id: (json['answers'] != null &&
          json['answers'] is List &&
          json['answers'].isNotEmpty)
          ? json['answers'][0]['answer_id']?.toString() ?? ''
          : '',
      studentName: json['student_name']?.toString() ?? '',
      studentAvatar: json['studentAvatar']?.toString() ?? '',
      status: () {
        final rawStatus = (json['answers'] is List && json['answers']!.isNotEmpty && json['answers']![0]['status'] != null)
            ? json['answers']![0]['status'].toString().toLowerCase()
            : '';
        print('rawst , $rawStatus');
        final fallbackStatus = json['submission_status']?.toString().toLowerCase();
        print('rawsts , $fallbackStatus');

        final statusString = (rawStatus == 'approved' || rawStatus == 'rejected')
            ? rawStatus
            : fallbackStatus;
        print('rawstaa , $statusString');

        return SubmissionStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == statusString,
          orElse: () => SubmissionStatus.assigned,
        );
      }(),
      submissionDate: json['completion_date']?.toString(),
      submissionUrl: json['submissionUrl']?.toString(),
      feedback: json['feedback']?.toString(),
      mobileno: json['mobile_no'],
      className: json['class'],
      section: json['section'],
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => Answer.fromJson(a))
          .toList(),
    );

  }
}

enum SubmissionStatus {
  assigned,
  rejected,
  incomplete,
  submitted,
  approved,
}

extension SubmissionStatusExtension on SubmissionStatus {

  String get displayName {
    switch (this) {
      case SubmissionStatus.assigned:
        return 'Assigned';
      case SubmissionStatus.submitted:
        return 'Review';
      case SubmissionStatus.rejected:
        return 'Rejected';
      case SubmissionStatus.incomplete:
        return 'Incomplete';
      case SubmissionStatus.approved:
        return 'Approved';

    }
  }

  Color get color {
    switch (this) {
      case SubmissionStatus.assigned:
        return const Color(0xFF6366F1); // Indigo
      case SubmissionStatus.submitted:
        return const Color(0xFF8B5CF6); // Purple
      case SubmissionStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case SubmissionStatus.incomplete:
        return const Color(0xFFF97316); // Orange
      case SubmissionStatus.approved:
        return const Color(0xFF10B981); // Green// Emerald Green
    }
  }
}

class VisionReviewPage extends StatefulWidget {
  final TeacherVisionVideo video;

  const VisionReviewPage({super.key, required this.video});

  @override
  State<VisionReviewPage> createState() => _VisionReviewPageState();
}

class _VisionReviewPageState extends State<VisionReviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StudentSubmission> _allSubmissions = [];
  List<StudentSubmission> _filteredSubmissions = [];
  String _selectedClassFilter = ''; // Default to class 1
  List<String> _availableClasses = [];
  String _selectedStatusFilter = '';
  bool _isLoading = false;
  DateTime? _entryTime;
  IconData _getStatusIcon(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.submitted:
        return Icons.rate_review_outlined;
      case SubmissionStatus.incomplete:
        return Icons.error_outline;
      case SubmissionStatus.rejected:
        return Icons.cancel_outlined;
      case SubmissionStatus.approved:
        return Icons.check_circle_outline;
      case SubmissionStatus.assigned:
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  void initState() {
    super.initState();
    _entryTime = DateTime.now();

    MixpanelService.track('AssignedVisionReviewScreen_Opened', properties: {
      'video_id': widget.video.id,
      'video_title': widget.video.title,
    });
    _tabController = TabController(length: 2, vsync: this);
    _fetchSubmissions();
  }
  @override
  void dispose() {
    // Track screen activity time when page closes
    if (_entryTime != null) {
      final duration = DateTime.now().difference(_entryTime!);
      MixpanelService.track('AssignedVisionReviewScreen_ActivityTime', properties: {
        'duration_seconds': duration.inSeconds,
        'video_id': widget.video.id,
      });
    }

    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<VisionProvider>(context, listen: false);
      final participants = await provider.getVisionParticipants(
        widget.video.id,
        _selectedClassFilter, // Pass the class filter
      );
      for (var json in participants) {
        print('📦 Raw JSON: $json');
      }
      _availableClasses = participants
          .map((json) => json['class']?.toString() ?? '')
          .where((className) => className.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // If our selected class isn't in the available classes, reset to first available
      if (_availableClasses.isNotEmpty && !_availableClasses.contains(_selectedClassFilter)) {
        _selectedClassFilter = _availableClasses.first;
      }
      _allSubmissions = participants.map((json) => StudentSubmission.fromJson(json)).toList();
      debugPrint('✅ Fetched ${_allSubmissions.length} submissions');

      _applyFilters();
    } catch (e) {
      debugPrint('❌ Error fetching submissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Center(
            child: Text(
              '⚠️ Error loading submissions. Please refresh the application.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),

      );

    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredSubmissions = _allSubmissions.where((submission) {
      // Status filter
      if (_selectedStatusFilter.isNotEmpty &&
          submission.status.displayName != _selectedStatusFilter) {
        return false;
      }

      // Class filter
      if (_selectedClassFilter.isNotEmpty &&
          submission.className != _selectedClassFilter) {
        return false;
      }

      return true;
    }).toList();

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vision Tracking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),

      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubmissionsList(),
                _buildSubmissionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _buildFilterChip('Status', _selectedStatusFilter, (value) {
            setState(() => _selectedStatusFilter = value);
            _applyFilters();
            MixpanelService.track('AssignedVisionReview_FilteredByStatus', properties: {
              'filter_value': value.isEmpty ? 'All' : value,
              'video_id': widget.video.id,
            });
          }),
          const SizedBox(width: 8),
          _buildClassFilter(), // Add class filter
          const Spacer(), // This will push the count to the right
          _buildTotalCount(),
        ],
      ),
    );
  }

  Widget _buildTotalCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Total: ${_allSubmissions.length}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildClassFilter() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _selectedClassFilter = value);
        _fetchSubmissions(); // Refetch data when class changes
        MixpanelService.track('AssignedVisionReview_FilteredByClass', properties: {
          'filter_value': value,
          'video_id': widget.video.id,
        });
      },
      itemBuilder: (context) => _availableClasses.map((className) {
        return PopupMenuItem(
          value: className,
          child: Text(className),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Class $_selectedClassFilter',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue, Function(String) onChanged) {
    List<String> options = [];

    switch (label) {
      case 'Status':
        options = SubmissionStatus.values.map((e) => e.displayName).toList();
        break;
    }

    return PopupMenuButton<String>(
      onSelected: (value) => onChanged(value == 'All' ? '' : value),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        ...options.map((option) => PopupMenuItem(
          value: option,
          child: Text(option),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
          color: selectedValue.isEmpty ? Colors.white : Colors.grey[200],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedValue.isEmpty ? label : selectedValue,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredSubmissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No submissions found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _filteredSubmissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(StudentSubmission submission) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            backgroundImage: submission.studentAvatar.isNotEmpty
                ? NetworkImage(submission.studentAvatar)
                : null,
            child: submission.studentAvatar.isEmpty
                ? Text(
              submission.studentName.isNotEmpty
                  ? submission.studentName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),

          // Student Name
          Expanded(
            child: Text(
              submission.studentName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Status Button(s)
          _buildStatusButtons(submission),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(StudentSubmission submission) {
    final bool isReviewed = submission.status == SubmissionStatus.approved ||
        submission.status == SubmissionStatus.rejected;

    final buttonStyle = ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      minimumSize: const Size(90, 36),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    if (isReviewed) {
      // Show status badge (disabled) + Details button
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: null,
            icon: Icon(
              submission.status == SubmissionStatus.approved
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: Colors.white,
              size: 16,
            ),
            label: Text(submission.status.displayName),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return submission.status.color.withOpacity(0.6);
                }
                return submission.status.color;
              }),
              foregroundColor: MaterialStateProperty.all(Colors.white),
            ),

          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              MixpanelService.track('AssignedVisionReview_DetailsClicked', properties: {
                'video_id': widget.video.id,
                'video_title': widget.video.title,
                'student_id': submission.id,
                'student_name': submission.studentName,
              });
              _showSubmissionDetails(submission);
            },
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text("Details"),
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.all(const Color(0xFF3B82F6)),
              foregroundColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
        ],
      );
    }

    // For submitted / incomplete / assigned
    return ElevatedButton.icon(
      onPressed: submission.status == SubmissionStatus.assigned ? null : () {
        if (submission.status == SubmissionStatus.submitted) {
          MixpanelService.track('AssignedVisionReview_ReviewClicked', properties: {
            'video_id': widget.video.id,
            'video_title': widget.video.title,
            'student_id': submission.id,
            'student_name': submission.studentName,
          });
        }
        _handleStatusAction(submission);
      },
      icon: Icon(
        _getStatusIcon(submission.status),
        size: 16,
        color: Colors.white,
      ),
      label: Text(submission.status.displayName),
      style: buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return submission.status.color.withOpacity(0.6);
          }
          return submission.status.color;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),

    );
  }

  void _handleStatusAction(StudentSubmission submission) {
    switch (submission.status) {
      case SubmissionStatus.submitted:
        _showReviewDialog(submission);
        break;
      case SubmissionStatus.rejected:
      case SubmissionStatus.incomplete:
        _showFeedbackDialog(submission);
        break;
      default:
        break;
    }
  }
  void _showSubmissionDetails(StudentSubmission submission) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Submission Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Student Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: submission.studentAvatar.isNotEmpty
                            ? NetworkImage(submission.studentAvatar)
                            : null,
                        child: submission.studentAvatar.isEmpty
                            ? Text(
                          submission.studentName.isNotEmpty
                              ? submission.studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.studentName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          if (submission.mobileno != null && submission.mobileno!.isNotEmpty)
                            Text(
                              submission.mobileno!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          Text(
                            '${submission.className} | ${submission.section}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: submission.status.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          submission.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (submission.submissionDate != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Submitted: ${submission.submissionDate}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Answers Section
                  const Text(
                    "Submission Answers",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: submission.answers.length,
                      itemBuilder: (context, index) {
                        final answer = submission.answers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Submission ${index + 1}: ${answer.questionText}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                              ),
                              const SizedBox(height: 6),
                              if (answer.answerType == 'image')
                                answer.imageUrl != null
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        answer.imageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Text('⚠️ Error loading image', style: TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                        children: [
                                          const TextSpan(
                                            text: 'Description: ',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          TextSpan(
                                            text: answer.description?.toUpperCase() ?? 'No description provided',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                                    : const Text('📎 No image available', style: TextStyle(color: Colors.black)),
                              if (answer.answerType == 'option') ...[
                                Text('Selected Option: ${answer.selectedOption?.toUpperCase() ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
                                Text('Correct Option: ${answer.correctOption?.toUpperCase() ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
                                Text(
                                  answer.isCorrect == true ? '✅ Correct' : '❌ Incorrect',
                                  style: TextStyle(
                                    color: answer.isCorrect == true ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _showReviewDialog(StudentSubmission submission) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Review Submission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Student Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: submission.studentAvatar.isNotEmpty
                              ? NetworkImage(submission.studentAvatar)
                              : null,
                          child: submission.studentAvatar.isEmpty
                              ? Text(
                            submission.studentName.isNotEmpty
                                ? submission.studentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              submission.studentName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            if (submission.mobileno != null && submission.mobileno!.isNotEmpty)
                              Text(
                                submission.mobileno!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            Text(
                              '${submission.className} | ${submission.section}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Answers Section
                    const Text(
                      "Submission Answers",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: submission.answers.length,
                        itemBuilder: (context, index) {
                          final answer = submission.answers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Submission ${index + 1}: ${answer.questionText}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                                const SizedBox(height: 6),
                                if (answer.answerType == 'image')
                                  answer.imageUrl != null
                                      ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          answer.imageUrl!,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Text('⚠️ Error loading image', style: TextStyle(color: Colors.black));
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 14, color: Colors.black),
                                          children: [
                                            const TextSpan(
                                              text: 'Description: ',
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            TextSpan(
                                              text: answer.description?.toUpperCase() ?? 'No description provided',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                      : const Text('📎 No image available', style: TextStyle(color: Colors.black)),
                                if (answer.answerType == 'option') ...[
                                  Text('Selected Option: ${answer.selectedOption?.toUpperCase() ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
                                  Text('Correct Option: ${answer.correctOption?.toUpperCase() ?? 'N/A'}', style: const TextStyle(color: Colors.black)),
                                  Text(
                                    answer.isCorrect == true ? '✅ Correct' : '❌ Incorrect',
                                    style: TextStyle(
                                      color: answer.isCorrect == true ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              MixpanelService.track('AssignedVisionReview_ApproveClicked', properties: {
                                'video_id': widget.video.id,
                                'student_id': submission.id,
                                'student_name': submission.studentName,
                              });
                              _updateSubmissionStatus(submission, SubmissionStatus.approved);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Approve", style: TextStyle(fontSize: 16 , color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              MixpanelService.track('AssignedVisionReview_RejectClicked', properties: {
                                'video_id': widget.video.id,
                                'student_id': submission.id,
                                'student_name': submission.studentName,
                              });
                              _updateSubmissionStatus(submission, SubmissionStatus.rejected);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Reject", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  void _showFeedbackDialog(StudentSubmission submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${submission.status.displayName} Submission'),
        content: Text('${submission.studentName}\'s submission was ${submission.status.displayName.toLowerCase()}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to detailed feedback/resubmission page
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
  void _updateSubmissionStatus(StudentSubmission submission, SubmissionStatus newStatus) async {
    final visionProvider = Provider.of<VisionProvider>(context, listen: false);

    try {
      final statusResponse = await visionProvider.getSubmissionStatus(submission.id, newStatus);
      debugPrint("📦 API Submission Status Response: $statusResponse");

      // Update local submission status
      setState(() {
        final index = _allSubmissions.indexWhere((s) => s.id == submission.id);
        if (index != -1) {
          _allSubmissions[index] = StudentSubmission(
            id: submission.id,
            studentName: submission.studentName,
            studentAvatar: submission.studentAvatar,
            status: newStatus,
            submissionDate: submission.submissionDate,
            submissionUrl: submission.submissionUrl,
            feedback: submission.feedback,
            answers: submission.answers,
          );
        }
      });

      _applyFilters();

      // ✅ If approved, show reward modal
      if (newStatus == SubmissionStatus.approved) {
        int coinValue = widget.video.levelInfo?.teacherCorrectSubmissionPoints ?? 0;

        // Show the coin reward popup
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You have been rewarded with $coinValue coins! 🎉',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      'Great!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      }

    } catch (e) {
      debugPrint("❌ Error calling getSubmissionStatus: $e");
    }
  }
}