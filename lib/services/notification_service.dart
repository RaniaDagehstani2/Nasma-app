// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     tz.initializeTimeZones(); // Ensure timezone support

//     const AndroidInitializationSettings androidInitSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     final InitializationSettings initSettings = InitializationSettings(
//       android: androidInitSettings,
//     );

//     await _notificationsPlugin.initialize(initSettings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//       if (response.payload == "taken") {
//         print("✅ Medication Taken");
//       } else if (response.payload == "remind_me_later") {
//         print("🔁 Reminder Rescheduled");
//         _rescheduleReminder();
//       }
//     });
//   }

//   static Future<void> scheduleNotification(
//       {required int id,
//       required String title,
//       required String body,
//       required DateTime scheduledTime}) async {
//     await _notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'medication_channel',
//           'Medication Reminders',
//           importance: Importance.max,
//           priority: Priority.high,
//           ongoing: true, // Keep it persistent
//           actions: [
//             AndroidNotificationAction(
//               'taken',
//               '✅ Taken',
//               showsUserInterface: true,
//             ),
//             AndroidNotificationAction(
//               'remind_me_later',
//               '🔁 Remind Me Later',
//               showsUserInterface: true,
//             ),
//           ],
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   static Future<void> _rescheduleReminder() async {
//     // Reschedule after 15 minutes
//     DateTime newTime = DateTime.now().add(Duration(minutes: 15));
//     await scheduleNotification(
//       id: 999,
//       title: "Medication Reminder",
//       body: "It's time to take your medication!",
//       scheduledTime: newTime,
//     );
//   }

//   static Future<void> cancelAll() async {
//     await _notificationsPlugin.cancelAll();
//   }
// }

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); // ✅ Set Riyadh Timezone

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print("🔴 All scheduled notifications have been canceled!");
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    DateTime now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      scheduledTime =
          scheduledTime.add(Duration(days: 1)); // ✅ Move to next day if past
    }

    tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    print("📅 Scheduling notification at: ${scheduledDate.toLocal()}");
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          actions: [
            AndroidNotificationAction('taken', '✅ Taken',
                showsUserInterface: true),
            AndroidNotificationAction('remind_me_later', '🔁 Remind Me Later',
                showsUserInterface: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
