// To parse this JSON data, do
//
//     final allStudentReportModel = allStudentReportModelFromJson(jsonString);

import 'dart:convert';

AllStudentReportModel allStudentReportModelFromJson(String str) =>
    AllStudentReportModel.fromJson(json.decode(str));

String allStudentReportModelToJson(AllStudentReportModel data) =>
    json.encode(data.toJson());

class AllStudentReportModel {
  int? status;
  Data? data;
  String? message;

  AllStudentReportModel({
    this.status,
    this.data,
    this.message,
  });

  factory AllStudentReportModel.fromJson(Map<String, dynamic> json) =>
      AllStudentReportModel(
        status: json["status"],
        data: json["data"] == null || json["data"].toString() == "[]"
            ? null
            : Data.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data?.toJson(),
        "message": message,
      };
}

class Data {
  List<Student>? student;
  int? totalMissionAssigned;
  int? totalMission;
  int? totalMissionIncomplete;
  int? totalVisionAssigned;
  int? totalVision;
  int? totalVisionIncomplete;
  int? totalQuiz;
  int? totalPuzzle;
  int? totalCoins;
  int? quizTotalCoins;
  int? totalMissionCoins;
  int? totalVisionCoins;
  int? coinsRedeemed;
  double? visionCompletionRate;
  double? missionCompletionRate;

  Data({
    this.student,
    this.totalMissionAssigned,
    this.totalMission,
    this.totalMissionIncomplete,
    this.totalVisionAssigned,
    this.totalVision,
    this.totalVisionIncomplete,
    this.totalQuiz,
    this.totalPuzzle,
    this.totalCoins,
    this.totalMissionCoins,
    this.totalVisionCoins,
    this.coinsRedeemed,
    this.visionCompletionRate,
    this.missionCompletionRate,
    this.quizTotalCoins,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        student: json["student"] == null
            ? []
            : List<Student>.from(
                (json["student"] as List).map((x) => Student.fromJson(x))),
        totalMissionAssigned: json["total_mission_assigned"]?.toInt(),
        totalMission: json["total_mission"]?.toInt(),
        totalMissionIncomplete: json["total_mission_incomplete"]?.toInt(),
        totalVisionAssigned: json["total_vision_assigned"]?.toInt(),
        totalVision: json["total_vision"]?.toInt(),
        totalVisionIncomplete: json["total_vision_incomplete"]?.toInt(),
        totalQuiz: json["total_quiz"]?.toInt(),
        totalPuzzle: json["total_puzzle"]?.toInt(),
        totalCoins: json["total_coins"]?.toInt(),
        totalMissionCoins: json["total_coins_mission"]?.toInt(),
        totalVisionCoins: json["total_coins_vision"]?.toInt(),
        coinsRedeemed: json["total_coins_redeemed"]?.abs().toInt(),
        visionCompletionRate:
            (json["vision_completion_rate"] as num?)?.toDouble(),
        missionCompletionRate:
            (json["mission_completion_rate"] as num?)?.toDouble(),
        quizTotalCoins: json["total_coins_quiz"]?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        "student": student == null
            ? []
            : List<dynamic>.from(student!.map((x) => x.toJson())),
        "total_mission_assigned": totalMissionAssigned,
        "total_mission": totalMission,
        "total_mission_incomplete": totalMissionIncomplete,
        "total_vision_assigned": totalVisionAssigned,
        "total_vision": totalVision,
        "total_vision_incomplete": totalVisionIncomplete,
        "total_quiz": totalQuiz,
        "total_puzzle": totalPuzzle,
        "total_coins": totalCoins,
        "total_coins_redeemed": coinsRedeemed,
        "vision_completion_rate": visionCompletionRate,
        "mission_completion_rate": missionCompletionRate,
        "total_coins_quiz": quizTotalCoins,
      };
}

class Student {
  User? user;
  int? missionAssigned;
  int? mission;
  int? missionIncomplete;
  int? visionAssigned;
  int? vision;
  int? visionIncomplete;
  int? quiz;
  int? totalQuizCoins;
  int? riddle;
  int? puzzle;
  int? coins;
  int? coinsRedeemed;
  double? missionCompletionRate;
  double? visionCompletionRate;
  int? totalMissionCoins;
  int? totalVisionCoins;

  Student({
    this.user,
    this.missionAssigned,
    this.mission,
    this.missionIncomplete,
    this.visionAssigned,
    this.vision,
    this.visionIncomplete,
    this.quiz,
    this.riddle,
    this.puzzle,
    this.coins,
    this.totalQuizCoins,
    this.coinsRedeemed,
    this.missionCompletionRate,
    this.visionCompletionRate,
    this.totalMissionCoins,
    this.totalVisionCoins,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        missionAssigned: (json["mission_assigned"] as num?)?.toInt(),
        mission: (json["mission"] as num?)?.toInt(),
        missionIncomplete: (json["mission_incomplete"] as num?)?.toInt(),
        visionAssigned: (json["vision_assigned"] as num?)?.toInt(),
        vision: (json["vision"] as num?)?.toInt(),
        visionIncomplete: (json["vision_incomplete"] as num?)?.toInt(),
        quiz: (json["quiz"] as num?)?.toInt(),
        totalQuizCoins: (json["coins_quiz"] as num?)?.toInt(),
        riddle: (json["riddle"] as num?)?.toInt(),
        puzzle: (json["puzzle"] as num?)?.toInt(),
        coins: (json["coins"] as num?)?.toInt(),
        totalMissionCoins: (json["coins_mission"] as num?)?.toInt(),
        totalVisionCoins: (json["coins_vision"] as num?)?.toInt(),
        coinsRedeemed: (json["coins_redeemed"] as num?)?.abs().toInt(),
        visionCompletionRate:
            (json["vision_completion_rate"] as num?)?.toDouble(),
        missionCompletionRate:
            (json["mission_completion_rate"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
        "mission_assigned": missionAssigned,
        "mission": mission,
        "mission_incomplete": missionIncomplete,
        "vision_assigned": visionAssigned,
        "vision": vision,
        "vision_incomplete": visionIncomplete,
        "quiz": quiz,
        "coins_quiz": totalQuizCoins,
        "riddle": riddle,
        "puzzle": puzzle,
        "coins": coins,
        "coins_mission": totalMissionCoins,
        "coins_vision": totalVisionCoins,
        "coins_redeemed": coinsRedeemed,
        "mission_completion_rate": missionCompletionRate,
        "vision_completion_rate": visionCompletionRate,
      };
}

class User {
  int? id;
  String? name;
  dynamic email;
  String? mobileNo;
  dynamic username;
  School? school;
  Section? section;
  Grade? grade;
  String? state;
  dynamic profileImage;

  User({
    this.id,
    this.name,
    this.email,
    this.mobileNo,
    this.username,
    this.school,
    this.section,
    this.grade,
    this.state,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        mobileNo: json["mobile_no"],
        username: json["username"],
        school: json["school"] == null ? null : School.fromJson(json["school"]),
        section:
            json["section"] == null ? null : Section.fromJson(json["section"]),
        grade: json["grade"] == null ? null : Grade.fromJson(json["grade"]),
        state: json["state"],
        profileImage: json["profile_image"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "mobile_no": mobileNo,
        "username": username,
        "school": school?.toJson(),
        "section": section?.toJson(),
        "grade": grade?.toJson(),
        "state": state,
        "profile_image": profileImage,
      };
}

class School {
  int? id;
  String? name;
  String? state;
  String? city;
  int? code;

  School({
    this.id,
    this.name,
    this.state,
    this.city,
    this.code,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json["id"],
        name: json["name"],
        state: json["state"],
        city: json["city"],
        code: json["code"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "state": state,
        "city": city,
        "code": code,
      };
}

class Section {
  int? id;
  String? name;

  Section({
    this.id,
    this.name,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Grade {
  int? id;
  String? name;

  Grade({
    this.id,
    this.name,
  });

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
