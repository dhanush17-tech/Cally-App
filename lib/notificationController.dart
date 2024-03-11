import 'package:ai_calendar_app/views/journalHome.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationController {
  @pragma("vm: entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm: entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}
  @pragma("vm: entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction,BuildContext context) async {
    if (receivedAction.channelKey == "daily_reminder") {
      Navigator.push(context, MaterialPageRoute(builder: (c) => JournalHome()));
    }
    if (receivedAction.buttonKeyPressed == 'OPEN_MEETING') {
      String? link = receivedAction.payload?['meetingLink'];
      if (link != null && link.isNotEmpty) {
        if (await canLaunch(link)) {
          await launch(link);
        } else {
          print('Could not launch $link');
          // Optionally, show some error message to the user
        }
      }
    }
  }
}
