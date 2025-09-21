import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/subject_level_list/presentation/pages/quiz_topic_list_page.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';

import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/image_helper.dart';
import '../../../../common/helper/string_helper.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
class LevelQuizWidget extends StatelessWidget {

  final SubjectLevelProvider provider;
  final String levelId;
  final String subjectId;

  const LevelQuizWidget({super.key, required this.provider, required this.levelId, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              StringHelper.quiz,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 10),
            Tooltip(
              message: "Quiz time! Earn coins and unlock\nrewards by playing quizzes.",
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: ColorCode.defaultBgColor,
              ),
              showDuration: const Duration(seconds: 1),
              triggerMode: TooltipTriggerMode.manual,
              key: tooltipKey,
              margin: const EdgeInsets.only(left: 30),
              padding: const EdgeInsets.all(15),
              child: InkWell(
                onTap: () {
                  tooltipKey.currentState?.ensureTooltipVisible();
                  // Mixpanel Tracking
                  MixpanelService.track("Quiz Info Icon Clicked", properties: {
                    "level_id": levelId,
                    "subject_id": subjectId,
                  });
                },
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: ColorCode.buttonColor,
                  child: Text(
                    "i",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffFF7FAD),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const Positioned(
                top: 25,
                left: 20,
                child: Text(
                  StringHelper.quizMsg,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: 20,
                child: InkWell(
                  onTap: () {
                    // Mixpanel Tracking
                    MixpanelService.track("Start Quiz Button Clicked", properties: {
                      "level_id": levelId,
                      "subject_id": subjectId,
                    });
                    push(
                      context: context,
                      page: QuizTopicListPage(
                        provider: provider,
                        levelId: levelId,
                        subjectId: subjectId,
                      ),
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height * 0.04,
                    width: MediaQuery.of(context).size.width * 0.28,
                    decoration: BoxDecoration(
                      color: const Color(0xffCB1255),
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                    child:  const Text(
                      StringHelper.startQuiz,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  alignment: Alignment.topRight,
                  height: 135,
                  child: Image.asset(
                    ImageHelper.quizFrame,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
