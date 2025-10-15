// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as d;
import 'dart:typed_data';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lifelab3/src/common/utils/show_download_notifications.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_grade_section_model.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_mission_list_model.dart';
import 'package:lifelab3/src/teacher/student_progress/model/teacher_mission_participant_model.dart';
import 'package:lifelab3/src/teacher/teacher_tool/model/all_student_report_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../teacher_tool/services/tool_services.dart';
import '../model/student_missions_model.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';

class StudentProgressProvider extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();

  AllStudentReportModel? allStudentReportModel;
  StudentMissionsModel? studentMissionsModel;
  TeacherGradeSectionModel? teacherGradeSectionModel;
  TeacherMissionListModel? teacherMissionListModel;
  TeacherMissionParticipantModel? teacherMissionParticipantModel;
  bool isImageProcessing = false;

  void getAllStudent() async {
    Response response = await ToolServices().getAllStudentReport();

    if (response.statusCode == 200) {
      allStudentReportModel = AllStudentReportModel.fromJson(response.data);
      notifyListeners();
    } else {
      allStudentReportModel = null;
    }
  }

  void getAllStudentMissionList({required String userId}) async {
    Response response =
        await ToolServices().getAllStudentMissionList(userId: userId);

    if (response.statusCode == 200) {
      studentMissionsModel = StudentMissionsModel.fromJson(response.data);
      notifyListeners();
    } else {
      studentMissionsModel = null;
    }
  }

  void getTeacherGrade() async {
    Response response = await ToolServices().getTeacherGrade();

    if (response.statusCode == 200) {
      teacherGradeSectionModel =
          TeacherGradeSectionModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherGradeSectionModel = null;
    }
  }

  void getClassStudent(String gradeId, {String? timeline}) async {
    // Build API URL
    String url = ApiHelper.baseUrl + ApiHelper.classStudent + gradeId;
    if (timeline != null && timeline.isNotEmpty && timeline != "All") {
      url += "?timeline=$timeline";
    }

    print("CALLING API: $url");

    try {
      Response response = await ToolServices().getClassStudentReport(
        gradeId,
        timeline: timeline,
      );

      print("API Hit Status: ${response.statusCode}");
      debugPrint(jsonEncode(response.data), wrapWidth: 1024);

      if (response.statusCode == 200) {
        allStudentReportModel = AllStudentReportModel.fromJson(response.data);

        // DEBUG: Log what got parsed into the model
        if (allStudentReportModel?.data != null) {
          print(" PARSED MODEL VALUES:");
          print("  - totalVision: ${allStudentReportModel!.data!.totalVision}");
          print(
              "  - totalMission: ${allStudentReportModel!.data!.totalMission}");
          print("  - totalQuiz: ${allStudentReportModel!.data!.totalQuiz}");
          print("  - totalCoins: ${allStudentReportModel!.data!.totalCoins}");

          // TEMPORARY WORKAROUND: Calculate totals manually if API returns 0
          if ((allStudentReportModel!.data!.totalVision == 0 ||
                  allStudentReportModel!.data!.totalMission == 0) &&
              allStudentReportModel!.data!.student != null) {
            int calculatedVision = 0;
            int calculatedMission = 0;

            for (var student in allStudentReportModel!.data!.student!) {
              calculatedVision += student.vision ?? 0;
              calculatedMission += student.mission ?? 0;
            }

            allStudentReportModel!.data!.totalVision = calculatedVision;
            allStudentReportModel!.data!.totalMission = calculatedMission;

            print(" FRONTEND WORKAROUND APPLIED:");
            print("  Calculated totalVision: $calculatedVision");
            print("  Calculated totalMission: $calculatedMission");
          }
        } else {
          print("allStudentReportModel.data is NULL after parsing!");
        }

        notifyListeners();
      } else {
        allStudentReportModel = null;
        notifyListeners();
        Fluttertoast.showToast(msg: "Failed to fetch class data");
      }
    } catch (e) {
      print("Error fetching class students: $e");
      allStudentReportModel = null;
      notifyListeners();
      Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
    }
  }

  void getTeacherMission(Map<String, dynamic> data) async {
    Response response = await ToolServices().getAssignMissionData(
      type: data["type"],
      subjectId: data["la_subject_id"],
      levelId: data["la_level_id"],
    );
    if (response.statusCode == 200) {
      teacherMissionListModel = TeacherMissionListModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherMissionListModel = null;
    }
  }

  void getTeacherMissionParticipant(String missionId) async {
    Response response =
        await ToolServices().getTeacherMissionParticipant(missionId: missionId);

    if (response.statusCode == 200) {
      d.log("Data ${jsonEncode(response.data)}");
      teacherMissionParticipantModel =
          TeacherMissionParticipantModel.fromJson(response.data);
      notifyListeners();
    } else {
      teacherMissionParticipantModel = null;
    }
  }

  Future<SubmitMissionResponse?> submitApproveReject({
    required int status,
    required String comment,
    required String studentId,
    required BuildContext context,
    required String missionId,
  }) async {
    Loader.show(
      context,
      progressIndicator: const CircularProgressIndicator(),
      overlayColor: Colors.black54,
    );

    try {
      Response? response =
          await ToolServices().submitTeacherMissionApproveReject(
        status: status,
        comment: comment,
        studentId: studentId,
      );

      Loader.hide();

      if (response != null && response.statusCode == 200) {
        Fluttertoast.showToast(msg: response.data["message"]);

        // Parse and return the API response
        return SubmitMissionResponse.fromJson(response.data);
      } else {
        Fluttertoast.showToast(msg: "Try again later");
      }
    } catch (e) {
      Loader.hide();
      Fluttertoast.showToast(msg: "Try again later");
    }

    return null;
  }

//download image
  void downloadImage(BuildContext context, GlobalKey boundaryKey) async {
    int androidVersion = 0;
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var release = androidInfo.version.release;
      androidVersion = int.tryParse(release.split(".").first) ?? 0;
    }

    var randomNum = Random();
    Directory? directory;
    var statusPermission = androidVersion < 12
        ? (await Permission.storage.request())
        : PermissionStatus.granted;
    if (statusPermission.isDenied) return;

    if (statusPermission.isGranted) {
      Loader.show(
        context,
        progressIndicator: const CircularProgressIndicator(),
        overlayColor: Colors.black54,
      );
      try {
        isImageProcessing = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));

        RenderRepaintBoundary? boundary = boundaryKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;

        var image = await boundary.toImage(pixelRatio: 3);
        ByteData? byteData =
            await image.toByteData(format: ImageByteFormat.png);
        Uint8List? uInt8list = byteData!.buffer.asUint8List();

        if (Platform.isIOS) {
          directory = await getTemporaryDirectory();
          if (!await directory.exists())
            await directory.create(recursive: true);
          final file = await File(
                  '${directory.path}/Lifelab_${randomNum.nextInt(1000000)}.png')
              .create();
          await file.writeAsBytes(uInt8list);
          //show notification
          if (await file.exists()) {
            await showDownloadNotification(file.path);
          } else {
            Fluttertoast.showToast(msg: "File not saved!");
          }
          Fluttertoast.showToast(msg: 'Downloaded');
        } else {
          directory = await getExternalStorageDirectory();
          File file = await File(
                  "/storage/emulated/0/Download/Lifelab_${randomNum.nextInt(1000000)}.png")
              .create(recursive: true);
          await file.writeAsBytes(uInt8list);
          //show notification
          if (await file.exists()) {
            await showDownloadNotification(file.path);
          } else {
            Fluttertoast.showToast(msg: "File not saved!");
          }
          Fluttertoast.showToast(msg: 'Downloaded');
        }
        Loader.hide();
      } catch (e) {
        Loader.hide();
        Fluttertoast.showToast(msg: "Please try again later!");
      }
      isImageProcessing = false;
      notifyListeners();
    }
  }
}
