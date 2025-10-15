import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/teacher/student_progress/presentations/pages/student_preogress_details_page.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';

import '../../../../common/helper/image_helper.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class CommonStudentWidget extends StatelessWidget {
  final String sectionName;
  final int index;
  final StudentProgressProvider provider;

  const CommonStudentWidget(
      {super.key,
      required this.sectionName,
      required this.index,
      required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 15, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 2,
            ),
          ]),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              provider.allStudentReportModel!.data!.student![index].user!
                          .profileImage !=
                      null
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(ApiHelper.imgBaseUrl +
                          provider.allStudentReportModel!.data!.student![index]
                              .user!.profileImage!),
                    )
                  : const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(ImageHelper.profileImg),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.allStudentReportModel!.data!.student![index]
                              .user!.name ??
                          "",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Class: $sectionName",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      provider.allStudentReportModel!.data!.student![index]
                              .user!.school?.name ??
                          "",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${provider.allStudentReportModel!.data!.student![index].user!.school?.state ?? ""}, ${provider.allStudentReportModel!.data!.student![index].user!.school?.city ?? ""}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Details
                  InkWell(
                    onTap: () {
                      final student =
                          provider.allStudentReportModel!.data!.student![index];
                      final studentName = student.user!.name ?? "Unknown";
                      final studentId = student.user!.id?.toString() ?? "";

                      MixpanelService.track(
                          "CommonStudentWidget_ViewDetailedReportClicked",
                          properties: {
                            "student_name": studentName,
                            "student_id": studentId,
                            "section_name": sectionName,
                          });
                      push(
                        context: context,
                        page: StudentProgressDetailsPage(
                          index: index,
                          provider: provider,
                          sectionName: sectionName,
                        ),
                      );
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      height: 25,
                      width: 113,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.blue,
                      ),
                      child: const Center(
                        child: Text(
                          "View detailed report",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          //details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    provider
                        .allStudentReportModel!.data!.student![index].vision!
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
                    provider
                        .allStudentReportModel!.data!.student![index].mission!
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
                    provider.allStudentReportModel!.data!.student![index].quiz!
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
                    provider.allStudentReportModel!.data!.student![index].coins!
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
                    provider.allStudentReportModel!.data!.student![index]
                        .coinsRedeemed!
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
        ],
      ),
    );
  }
}
