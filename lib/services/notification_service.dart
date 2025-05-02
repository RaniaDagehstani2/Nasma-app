// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/standalone.dart' as tz;

// class NotificationService {
//   static late String _currentPatientId; // ✅ Add this

//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize(String patientId) async {
//     _currentPatientId = patientId;
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); // ✅ Set Riyadh Timezone

//     const AndroidInitializationSettings androidInitSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     final InitializationSettings initSettings = InitializationSettings(
//       android: androidInitSettings,
//     );

//     // ------- detects what button was pressed and performs the correct action -----------
//     await _notificationsPlugin.initialize(initSettings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//       int id = response.id ?? -1;
//       if (id == -1) return;

//       String action = response.payload ?? "";
//       print("📩 Notification Action Received: $action");

//       if (action == "taken") {
//         _logMedicationStatus(id, "Taken");
//       } else if (action == "remind_me_later") {
//         _logMedicationStatus(id, "Delayed");
//         _rescheduleReminder(id);
//       }
//     });
//   }

// //-------------------------Safaadd this sectionfor Emergncy Alert ------------------------------
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'emergency_channel',
//       'Emergency Alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//     );

//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
//   }

// //-----------------------------end Safa section -----------------------------------------------------
//   static Future<void> cancelAll() async {
//     await _notificationsPlugin.cancelAll();
//     print("🔴 All scheduled notifications have been canceled!");
//   }

//   static Future<void> scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//   }) async {
//     DateTime now = DateTime.now();
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(Duration(days: 1));
//     }

//     tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

//     DatabaseReference ref = FirebaseDatabase.instance.ref();

//     // 🟢 Get patient name
//     DataSnapshot snap =
//         await ref.child("Patient").child(_currentPatientId).get();

//     String fullName = "Unknown Patient";
//     String medName = "your medication"; // default
//     String dosage = "";

//     if (snap.exists && snap.value != null && snap.value is Map) {
//       var data = Map<String, dynamic>.from(snap.value as Map);
//       String fname = data["Fname"] ?? "";
//       String lname = data["Lname"] ?? "";
//       fullName = "$fname $lname".trim();

//       String treatmentPlanId = data["TreatmentPlan_ID"] ?? "";

//       if (treatmentPlanId.isNotEmpty) {
//         DataSnapshot tpSnap =
//             await ref.child("TreatmentPlan").child(treatmentPlanId).get();

//         if (tpSnap.exists && tpSnap.value != null && tpSnap.value is Map) {
//           var tpData = Map<String, dynamic>.from(tpSnap.value as Map);

//           if (tpData.containsKey("MedicationName") &&
//               tpData["MedicationName"] is Map) {
//             medName = tpData["MedicationName"]["name1"] ?? medName;
//           }

//           if (tpData.containsKey("Dosage") && tpData["Dosage"] is Map) {
//             dosage = tpData["Dosage"]["inhale1"] ?? "";
//           }
//         }
//       }
//     }

//     String newTitle = "Reminder for $fullName";
//     String newBody = "Time to take your $medName (${dosage})";

//     await _notificationsPlugin.zonedSchedule(
//       id,
//       newTitle,
//       newBody,
//       scheduledDate,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'medication_channel',
//           'Medication Reminders',
//           importance: Importance.max,
//           priority: Priority.high,
//           ongoing: true,
//           actions: [
//             AndroidNotificationAction('taken', '✅ Taken',
//                 showsUserInterface: true),
//             AndroidNotificationAction('remind_me_later', '🔁 Remind Me Later',
//                 showsUserInterface: true),
//           ],
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   //------------ Firebase Integration for Medication Tracking -------------------------
//   static Future<void> _logMedicationStatus(int id, String status) async {
//     DatabaseReference ref = FirebaseDatabase.instance.ref();
//     DateTime now = DateTime.now();
//     String date = "\${now.year}-\${now.month}-\${now.day}";

//     // ✅ Convert time to AM/PM format
//     String hour =
//         (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
//     String minute = now.minute.toString().padLeft(2, '0');
//     String period = (now.hour >= 12) ? "PM" : "AM";
//     String formattedTime = "$hour:$minute $period"; // e.g., "2:30 PM"

//     // 🔥 Check the last status before logging a new one
//     DatabaseEvent lastEvent =
//         await ref.child("MedicationHistory").orderByKey().limitToLast(1).once();

//     if (lastEvent.snapshot.value != null) {
//       Map<dynamic, dynamic> lastEntry =
//           lastEvent.snapshot.value as Map<dynamic, dynamic>;
//       String lastKey = lastEntry.keys.first;
//       Map lastData = lastEntry[lastKey];

//       // 🔴 If the last status was "Delayed" but never "Taken", update to "Missed"
//       if (lastData["status"] == "Delayed") {
//         await ref
//             .child("MedicationHistory")
//             .child(lastKey)
//             .update({"status": "Missed"});
//         print("❌ Last medication entry updated to 'Missed'");
//       }
//     }

//     // ✅ Now log the new status with AM/PM format
//     await ref.child("MedicationHistory").push().set({
//       "date": date,
//       "time": formattedTime, // ✅ Now in AM/PM format
//       "status": status,
//     });

//     print("✅ Medication status logged: $status at $formattedTime");
//   }

//   //--------- a new notification is scheduled 15 minutes later ----------------
//   static Future<void> _rescheduleReminder(int id) async {
//     DateTime newTime = DateTime.now().add(Duration(minutes: 15));

//     await scheduleNotification(
//       id: id,
//       title: "Medication Reminder",
//       body: "It's time to take your medication!",
//       scheduledTime: newTime,
//     );

//     print("🔁 Reminder rescheduled for: \${newTime.toLocal()}");
//   }

//   //--------- Check Partial Adherence (Orange Warning) ----------------
//   static Future<void> checkPartialAdherence(String userId, String date) async {
//     DatabaseReference ref = FirebaseDatabase.instance.ref();
//     DatabaseEvent event = await ref
//         .child("Users")
//         .child(userId)
//         .child("MedicationHistory")
//         .orderByChild("date")
//         .equalTo(date)
//         .once();

//     if (event.snapshot.value != null) {
//       Map<dynamic, dynamic> history =
//           event.snapshot.value as Map<dynamic, dynamic>;
//       int totalDoses = history.length;
//       int takenDoses =
//           history.values.where((entry) => entry["status"] == "Taken").length;

//       if (takenDoses > 0 && takenDoses < totalDoses) {
//         print(
//             "🟠 Warning: Partial Adherence detected for user $userId on $date");
//         // Handle warning notification or UI update
//       }
//     }
//   }
// }
// ================================================================================================
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/standalone.dart' as tz;

// class NotificationService {
//   static late String _currentPatientId;

//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize(String patientId) async {
//     _currentPatientId = patientId;
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

//     const AndroidInitializationSettings androidInitSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     final InitializationSettings initSettings = InitializationSettings(
//       android: androidInitSettings,
//     );

//     await _notificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _handleNotificationAction,
//       onDidReceiveBackgroundNotificationResponse: _handleNotificationAction,
//     );
//   }

//   @pragma('vm:entry-point')
//   static void _handleNotificationAction(NotificationResponse response) {
//     int id = response.id ?? -1;
//     if (id == -1) return;

//     String action = response.actionId ?? "";
//     print("📩 Notification Action Received: $action");

//     if (action == "taken") {
//       _logMedicationStatus(id, "Taken");
//     } else if (action == "remind_me_later") {
//       _logMedicationStatus(id, "Delayed");
//       _rescheduleReminder(id);
//     }
//   }

//   static Future<void> scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//   }) async {
//     DateTime now = DateTime.now();
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(Duration(days: 1));
//     }

//     tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

//     DatabaseReference ref = FirebaseDatabase.instance.ref();

//     DataSnapshot snap =
//         await ref.child("Patient").child(_currentPatientId).get();

//     String fullName = "Unknown Patient";
//     String medName = "your medication";
//     String dosage = "";

//     if (snap.exists && snap.value != null && snap.value is Map) {
//       var data = Map<String, dynamic>.from(snap.value as Map);
//       String fname = data["Fname"] ?? "";
//       String lname = data["Lname"] ?? "";
//       fullName = "$fname $lname".trim();

//       String treatmentPlanId = data["TreatmentPlan_ID"] ?? "";

//       if (treatmentPlanId.isNotEmpty) {
//         DataSnapshot tpSnap =
//             await ref.child("TreatmentPlan").child(treatmentPlanId).get();

//         if (tpSnap.exists && tpSnap.value != null && tpSnap.value is Map) {
//           var tpData = Map<String, dynamic>.from(tpSnap.value as Map);

//           if (tpData.containsKey("MedicationName") &&
//               tpData["MedicationName"] is Map) {
//             medName = tpData["MedicationName"]["name1"] ?? medName;
//           }

//           if (tpData.containsKey("Dosage") && tpData["Dosage"] is Map) {
//             dosage = tpData["Dosage"]["inhale1"] ?? "";
//           }
//         }
//       }
//     }

//     String newTitle = "Reminder for $fullName";
//     String newBody = "Time to take your $medName ($dosage)";

//     await _notificationsPlugin.zonedSchedule(
//       id,
//       newTitle,
//       newBody,
//       scheduledDate,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           'medication_channel',
//           'Medication Reminders',
//           importance: Importance.max,
//           priority: Priority.high,
//           ongoing: true,
//           actions: [
//             AndroidNotificationAction(
//               'taken',
//               '✅ Taken',
//               showsUserInterface: false,
//               cancelNotification: true,
//             ),
//             AndroidNotificationAction(
//               'remind_me_later',
//               '🔁 Remind Me Later',
//               showsUserInterface: false,
//               cancelNotification: true,
//             ),
//           ],
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   static Future<void> _logMedicationStatus(int id, String status) async {
//     DatabaseReference ref = FirebaseDatabase.instance.ref();
//     DateTime now = DateTime.now();
//     String date = "${now.year}-${now.month}-${now.day}";

//     String hour =
//         (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
//     String minute = now.minute.toString().padLeft(2, '0');
//     String period = (now.hour >= 12) ? "PM" : "AM";
//     String formattedTime = "$hour:$minute $period";
//     print("🔔 Logging medication status...");
//     print("🧾 Patient ID: $_currentPatientId");
//     print("🧾 Status: $status");

//     DataSnapshot medSnapshot = await ref
//         .child("Patient")
//         .child(_currentPatientId)
//         .child("MedicationHistory")
//         .get();

//     int nextIndex = 1;
//     if (medSnapshot.exists &&
//         medSnapshot.value != null &&
//         medSnapshot.value is Map) {
//       Map existing = Map<String, dynamic>.from(medSnapshot.value as Map);
//       List<String> keys = existing.keys
//           .where((k) => k.toString().startsWith("d"))
//           .map((k) => k.toString())
//           .toList();
//       keys.sort();
//       if (keys.isNotEmpty) {
//         String lastKey = keys.last;
//         int lastNum = int.tryParse(lastKey.replaceAll("d", "")) ?? 0;
//         nextIndex = lastNum + 1;

//         Map<String, dynamic> lastData =
//             Map<String, dynamic>.from(existing[lastKey]);
//         if (lastData["status"] == "Delayed") {
//           await ref
//               .child("Patient")
//               .child(_currentPatientId)
//               .child("MedicationHistory")
//               .child(lastKey)
//               .update({"status": "Missed"});
//           print("❌ Last medication entry updated to 'Missed'");
//         }
//       }
//     }

//     String newKey = "d$nextIndex";

//     await ref
//         .child("Patient")
//         .child(_currentPatientId)
//         .child("MedicationHistory")
//         .child(newKey)
//         .set({
//       "date": date,
//       "time": formattedTime,
//       "status": status,
//     });

//     print(
//         "✅ Medication status logged: $status at $formattedTime → under $newKey");
//   }

//   static Future<void> _rescheduleReminder(int id) async {
//     DateTime newTime = DateTime.now().add(Duration(minutes: 15));

//     await scheduleNotification(
//       id: id,
//       title: "Medication Reminder",
//       body: "It's time to take your medication!",
//       scheduledTime: newTime,
//     );

//     print("🔁 Reminder rescheduled for: ${newTime.toLocal()}");
//   }

//   static Future<void> cancelAll() async {
//     await _notificationsPlugin.cancelAll();
//     print("🔴 All scheduled notifications have been canceled!");
//   }
// }
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static late String _currentPatientId;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(String patientId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_patient_id', patientId);
    _currentPatientId = patientId;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    DateTime now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DataSnapshot snap =
        await ref.child("Patient").child(_currentPatientId).get();

    String fullName = "Unknown Patient";
    String medName = "your medication";
    String dosage = "";

    if (snap.exists && snap.value != null && snap.value is Map) {
      var data = Map<String, dynamic>.from(snap.value as Map);
      String fname = data["Fname"] ?? "";
      String lname = data["Lname"] ?? "";
      fullName = "$fname $lname".trim();

      String treatmentPlanId = data["TreatmentPlan_ID"] ?? "";

      if (treatmentPlanId.isNotEmpty) {
        DataSnapshot tpSnap =
            await ref.child("TreatmentPlan").child(treatmentPlanId).get();

        if (tpSnap.exists && tpSnap.value != null && tpSnap.value is Map) {
          var tpData = Map<String, dynamic>.from(tpSnap.value as Map);

          if (tpData.containsKey("MedicationName") &&
              tpData["MedicationName"] is Map) {
            medName = tpData["MedicationName"]["name1"] ?? medName;
          }

          if (tpData.containsKey("Dosage") && tpData["Dosage"] is Map) {
            dosage = tpData["Dosage"]["inhale1"] ?? "";
          }
        }
      }
    }

    String newTitle = "Reminder for $fullName";
    String newBody = "Time to take your $medName ($dosage)";

    await _notificationsPlugin.zonedSchedule(
      id,
      newTitle,
      newBody,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          actions: [
            AndroidNotificationAction(
              'taken',
              '✅ Taken',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'remind_me_later',
              '🔁 Remind Me Later',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> logMedicationStatus(
      String patientId, int id, String status) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DateTime now = DateTime.now();
    String date = "${now.year}-${now.month}-${now.day}";

    String hour =
        (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
    String minute = now.minute.toString().padLeft(2, '0');
    String period = (now.hour >= 12) ? "PM" : "AM";
    String formattedTime = "$hour:$minute $period";

    // String newKey = DateTime.now().millisecondsSinceEpoch.toString();
    int dayNumber = DateTime.now().day;
    String newKey = "d$dayNumber";

    await ref
        .child("Patient")
        .child(patientId)
        .child("MedicationHistory")
        .child(newKey)
        .set({
      "date": date,
      "time": formattedTime,
      "status": status,
    });

    print("✅ Medication status logged: $status at $formattedTime");
  }

  static Future<void> rescheduleReminder(String patientId, int id) async {
    DateTime newTime = DateTime.now().add(Duration(minutes: 15));
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(newTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      "Medication Reminder",
      "It's time to take your medication!",
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          actions: [
            AndroidNotificationAction(
              'taken',
              '✅ Taken',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'remind_me_later',
              '🔁 Remind Me Later',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("🔁 Reminder rescheduled for: ${newTime.toLocal()}");
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print("🔴 All scheduled notifications have been canceled!");
  }
}

@pragma('vm:entry-point')
void _handleNotificationAction(NotificationResponse response) async {
  await Firebase.initializeApp();

  // ✅ Load patientId from SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? patientId = prefs.getString('current_patient_id');

  if (patientId == null) return; // nothing to do

  int id = response.id ?? -1;
  if (id == -1) return;

  String action = response.actionId ?? "";
  print("📩 Foreground Notification Action Received: $action");

  if (action == "taken") {
    await NotificationService.logMedicationStatus(patientId, id, "Taken");
  } else if (action == "remind_me_later") {
    await NotificationService.logMedicationStatus(patientId, id, "Delayed");
    await NotificationService.rescheduleReminder(patientId, id);
  }
}

// -----------------------------------------------------------------------------
// ✅✅✅ Background actions (top level → this is the fix) ✅✅✅

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? patientId = prefs.getString('current_patient_id');

  if (patientId == null) return; // nothing to do, safe exit

  int id = response.id ?? -1;
  if (id == -1) return;

  String action = response.actionId ?? "";
  print("📩 Background Notification Action Received: $action");

  if (action == "taken") {
    await logMedicationStatusBackground(patientId, id, "Taken");
  } else if (action == "remind_me_later") {
    await logMedicationStatusBackground(patientId, id, "Delayed");
    await rescheduleReminderBackground(patientId, id);
  }
}

Future<void> logMedicationStatusBackground(
    String patientId, int id, String status) async {
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = database.ref();

  DateTime now = DateTime.now();
  String date = "${now.year}-${now.month}-${now.day}";

  String hour =
      (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
  String minute = now.minute.toString().padLeft(2, '0');
  String period = (now.hour >= 12) ? "PM" : "AM";
  String formattedTime = "$hour:$minute $period";

  // String newKey = DateTime.now().millisecondsSinceEpoch.toString();
  int dayNumber = DateTime.now().day;
  String newKey = "d$dayNumber";

  await ref
      .child("Patient")
      .child(patientId)
      .child("MedicationHistory")
      .child(newKey)
      .set({
    "date": date,
    "time": formattedTime,
    "status": status,
  });

  print("✅ [BG] Medication status logged: $status at $formattedTime");
}

Future<void> rescheduleReminderBackground(String patientId, int id) async {
  DateTime newTime = DateTime.now().add(Duration(minutes: 15));
  tz.TZDateTime scheduledDate = tz.TZDateTime.from(newTime, tz.local);

  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await notificationsPlugin.zonedSchedule(
    id,
    "Medication Reminder",
    "It's time to take your medication!",
    scheduledDate,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        actions: [
          AndroidNotificationAction(
            'taken',
            '✅ Taken',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'remind_me_later',
            '🔁 Remind Me Later',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );

  print("🔁 [BG] Reminder rescheduled for: ${newTime.toLocal()}");
}
