import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../../../profile/presentations/pages/profile_page.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';


class HomeAppBar extends StatelessWidget {
  final String name;
  final String? img;

  const HomeAppBar({required this.name, required this.img, super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
        child: Row(
          children: [
            // Drawer
            InkWell(
              onTap: () {
                MixpanelService.track('Menu Icon Clicked', properties: {
                  'user_name': name,
                });

                Scaffold.of(context).openDrawer();
              },
              child: Image.asset(
                ImageHelper.drawerIcon,
                height: 40,
              ),
            ),

            // Name
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  StringHelper.lifeApp,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "Hello! ",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      " $name",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),
            InkWell(
              onTap: () {
                MixpanelService.track('Profile Icon Clicked', properties: {
                  'user_name': name,
                });
                PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: const ProfilePage(),
                  withNavBar: false,
                );
              },
              child: img != null
                  ? CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          NetworkImage(ApiHelper.imgBaseUrl + img!),
                    )
                  : const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage(ImageHelper.profileImg),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
