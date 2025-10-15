//individual student report
import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class StudentProgressDetailsPage extends StatefulWidget {
  final String sectionName;
  final int index;
  final StudentProgressProvider provider;

  const StudentProgressDetailsPage(
      {super.key,
      required this.sectionName,
      required this.index,
      required this.provider});

  @override
  State<StudentProgressDetailsPage> createState() =>
      _StudentProgressDetailsPageState();
}

class _StudentProgressDetailsPageState
    extends State<StudentProgressDetailsPage> {
  final GlobalKey _studentDetailsKey = GlobalKey();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<StudentProgressProvider>(context, listen: false)
          .getAllStudentMissionList(
              userId: widget.provider.allStudentReportModel!.data!
                  .student![widget.index].user!.id!
                  .toString());
    });
    super.initState();
    MixpanelService.track("StudentProgressDetailsPage_View", properties: {
      "section_name": widget.sectionName,
      "student_name": widget.provider.allStudentReportModel!.data!
              .student![widget.index].user!.name ??
          "",
      "student_id": widget
          .provider.allStudentReportModel!.data!.student![widget.index].user!.id
          .toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProgressProvider>(context);
    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: 'Student Report',
        action: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: CustomButton(
            height: 30,
            width: 100,
            name: StringHelper.download,
            onTap: () {
              MixpanelService.track(
                  "StudentProgressDetailsPage_DownloadClicked",
                  properties: {
                    "student_name": widget.provider.allStudentReportModel!.data!
                            .student![widget.index].user!.name ??
                        "",
                    "student_id": widget.provider.allStudentReportModel!.data!
                        .student![widget.index].user!.id
                        .toString(),
                  });
              widget.provider.downloadImage(context, _studentDetailsKey);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: RepaintBoundary(
          key: _studentDetailsKey,
          child: ColoredBox(
            color:
                provider.isImageProcessing ? Colors.white : Colors.transparent,
            child: Column(
              children: [
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: widget.provider.allStudentReportModel!.data!
                              .student![widget.index].user!.profileImage !=
                          null
                      ? Image.network(ApiHelper.imgBaseUrl +
                          widget.provider.allStudentReportModel!.data!
                              .student![widget.index].user!.profileImage!)
                      : Image.asset(
                          ImageHelper.profileIcon,
                          width: MediaQuery.of(context).size.width * .4,
                        ),
                ),
                Text(
                  widget.provider.allStudentReportModel!.data!
                          .student![widget.index].user!.name ??
                      "",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Class: ${widget.sectionName}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.provider.allStudentReportModel!.data!
                          .student![widget.index].user!.school?.name ??
                      "",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "${widget.provider.allStudentReportModel!.data!.student![widget.index].user!.school?.state ?? ""}, ${widget.provider.allStudentReportModel!.data!.student![widget.index].user!.school?.city ?? ""}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Text(
                            widget.provider.allStudentReportModel!.data!
                                .student![widget.index].vision!
                                .toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Vision",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.black54,
                      ),
                      Column(
                        children: [
                          Text(
                            widget.provider.allStudentReportModel!.data!
                                .student![widget.index].mission!
                                .toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Mission",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.black54,
                      ),
                      Column(
                        children: [
                          Text(
                            widget.provider.allStudentReportModel!.data!
                                .student![widget.index].quiz!
                                .toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Quiz",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.black54,
                      ),
                      Column(
                        children: [
                          Text(
                            widget.provider.allStudentReportModel!.data!
                                .student![widget.index].coins!
                                .toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Coins\nEarned",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.black54,
                      ),
                      Column(
                        children: [
                          Text(
                            widget.provider.allStudentReportModel!.data!
                                .student![widget.index].coinsRedeemed!
                                .toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            "Coins\nRedeemed",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Vision & Mission Stats container
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: "Vision Stats "),
                            TextSpan(
                              text:
                                  "(Completion rate ${widget.provider.allStudentReportModel!.data!.student![widget.index].visionCompletionRate ?? 0}%)",
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Assigned",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].visionAssigned ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "Complete",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].vision ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "Coins Earned",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].totalVisionCoins ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: "Mission Stats "),
                            TextSpan(
                              text:
                                  "(Completion rate ${widget.provider.allStudentReportModel!.data!.student![widget.index].missionCompletionRate ?? 0}%)",
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Assigned",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].missionAssigned ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "Complete",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].mission ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "Coins Earned",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].totalMissionCoins ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      const Text('Quiz Set Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          )),
                      Row(
                        children: [
                          const Text(
                            "Total Quiz",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].quiz ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            "coins Earned",
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            "${widget.provider.allStudentReportModel!.data!.student![widget.index].totalQuizCoins ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
