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
import 'package:firebase_database/firebase_database.dart';
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

    // ------- detects what button was pressed and performs the correct action -----------
    await _notificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      int id = response.id ?? -1;
      if (id == -1) return;

      String action = response.payload ?? "";
      print("📩 Notification Action Received: $action");

      if (action == "taken") {
        _logMedicationStatus(id, "Taken");
      } else if (action == "remind_me_later") {
        _logMedicationStatus(id, "Delayed");
        _rescheduleReminder(id);
      }
    });
  }

//-------------------------Safaadd this sectionfor Emergncy Alert ------------------------------
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

//-----------------------------end Safa section -----------------------------------------------------
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

    print("📅 Scheduling notification at: \${scheduledDate.toLocal()}");
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

  //------------ Firebase Integration for Medication Tracking -------------------------
  static Future<void> _logMedicationStatus(int id, String status) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DateTime now = DateTime.now();
    String date = "\${now.year}-\${now.month}-\${now.day}";

    // ✅ Convert time to AM/PM format
    String hour =
        (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
    String minute = now.minute.toString().padLeft(2, '0');
    String period = (now.hour >= 12) ? "PM" : "AM";
    String formattedTime = "$hour:$minute $period"; // e.g., "2:30 PM"

    // 🔥 Check the last status before logging a new one
    DatabaseEvent lastEvent =
        await ref.child("MedicationHistory").orderByKey().limitToLast(1).once();

    if (lastEvent.snapshot.value != null) {
      Map<dynamic, dynamic> lastEntry =
          lastEvent.snapshot.value as Map<dynamic, dynamic>;
      String lastKey = lastEntry.keys.first;
      Map lastData = lastEntry[lastKey];

      // 🔴 If the last status was "Delayed" but never "Taken", update to "Missed"
      if (lastData["status"] == "Delayed") {
        await ref
            .child("MedicationHistory")
            .child(lastKey)
            .update({"status": "Missed"});
        print("❌ Last medication entry updated to 'Missed'");
      }
    }

    // ✅ Now log the new status with AM/PM format
    await ref.child("MedicationHistory").push().set({
      "date": date,
      "time": formattedTime, // ✅ Now in AM/PM format
      "status": status,
    });

    print("✅ Medication status logged: $status at $formattedTime");
  }

  //--------- a new notification is scheduled 15 minutes later ----------------
  static Future<void> _rescheduleReminder(int id) async {
    DateTime newTime = DateTime.now().add(Duration(minutes: 15));

    await scheduleNotification(
      id: id,
      title: "Medication Reminder",
      body: "It's time to take your medication!",
      scheduledTime: newTime,
    );

    print("🔁 Reminder rescheduled for: \${newTime.toLocal()}");
  }

  //--------- Check Partial Adherence (Orange Warning) ----------------
  static Future<void> checkPartialAdherence(String userId, String date) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref
        .child("Users")
        .child(userId)
        .child("MedicationHistory")
        .orderByChild("date")
        .equalTo(date)
        .once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> history =
          event.snapshot.value as Map<dynamic, dynamic>;
      int totalDoses = history.length;
      int takenDoses =
          history.values.where((entry) => entry["status"] == "Taken").length;

      if (takenDoses > 0 && takenDoses < totalDoses) {
        print(
            "🟠 Warning: Partial Adherence detected for user $userId on $date");
        // Handle warning notification or UI update
      }
    }
  }
}
