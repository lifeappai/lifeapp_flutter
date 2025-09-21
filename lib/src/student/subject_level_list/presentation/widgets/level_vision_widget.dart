import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/widgets/common_navigator.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';
import 'package:lifelab3/src/student/vision/presentations/vision_page.dart';
import '../../../../common/helper/color_code.dart';
import '../../../../common/helper/string_helper.dart';
import '../../../mission/presentations/pages/mission_page.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class LevelVisionWidget extends StatelessWidget {

  final SubjectLevelProvider provider;
  final String subjectId;
  final String levelId;

  LevelVisionWidget({super.key, required this.provider, required this.subjectId, required this.levelId});

  final GlobalKey<TooltipState> tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  StringHelper.vision,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 10),
                Tooltip(
                  message: "Complete fun activities, upload images \nto earn coins and unlock rewards.",
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
                      // 🔹 Track Info Icon Click
                      MixpanelService.track('Vision Info Icon Clicked', properties: {
                        'subjectId': subjectId,
                        'levelId': levelId,
                      });
                      tooltipKey.currentState?.ensureTooltipVisible();
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
                  color: const Color(0xFFFFF1B0),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const Positioned(
                top: 25,
                left: 20,
                child: Text(
                  "Lets get started with\nvision",
                  style: TextStyle(
                    color: Colors.black,
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
                    // 🔹 Track Get Started Button Click
                    MixpanelService.track('Vision Get Started Clicked', properties: {
                      'subjectId': subjectId,
                      'levelId': levelId,
                    });
                    push(
                      context: context,
                      page: VisionPage(
                        navName: 'Vision',
                        subjectId: subjectId,
                        levelId: levelId,
                      ),
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height * 0.04,
                    width: MediaQuery.of(context).size.width * 0.28,
                    decoration: BoxDecoration(
                      color: const Color(0xffff6500),
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                    child:  const Text(
                      StringHelper.getStarted,
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
                bottom: 5,
                child: Container(
                  alignment: Alignment.topRight,
                  height: 140,
                  child: Image.asset(
                    ImageHelper.visionIcon2,
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

