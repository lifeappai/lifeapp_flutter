import 'dart:convert';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lifelab3/main.dart';

Future<void> showDownloadNotification(String filePath) async {
  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(10000), // unique ID
    "Image Downloaded",
    "Tap to view the downloaded image",
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        icon: 'launch_background',
      ),
    ),
    payload: jsonEncode({
      "type": "image",
      "filePath": filePath,
    }),
  );
}
