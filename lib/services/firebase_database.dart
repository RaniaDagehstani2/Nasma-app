// import 'package:firebase_database/firebase_database.dart';

// class FirebaseService {
//   final DatabaseReference _treatmentPlansRef = FirebaseDatabase.instance
//       .ref()
//       .child('TreatmentPlan'); // ✅ Corrected path

//   // Add Treatment Plan to Firebase
//   Future<void> addTreatmentPlan({
//     required String treatmentPlanId,
//     required int actScore,
//     required String dosage,
//     required List<String> intakeTimes,
//     required bool isApproved,
//     required String medicationName,
//     required String stepNum,
//   }) async {
//     await _treatmentPlansRef.child(treatmentPlanId).set({
//       'ACT': actScore,
//       'dosage': dosage,
//       'intakeTimes': {'timeId1': intakeTimes[0], 'timeId2': intakeTimes[1]},
//       'isApproved': isApproved,
//       'name': medicationName,
//       'stepNum': stepNum,
//     });
//   }

//   // Fetch Treatment Plan Data by ID
//   Future<Map<String, dynamic>> getTreatmentPlan(String treatmentPlanId) async {
//     DataSnapshot treatmentPlanSnapshot =
//         await _treatmentPlansRef.child(treatmentPlanId).get();
//     if (treatmentPlanSnapshot.exists) {
//       Map<String, dynamic> treatmentPlanData =
//           Map<String, dynamic>.from(treatmentPlanSnapshot.value as Map);
//       return treatmentPlanData;
//     } else {
//       throw Exception("Treatment plan not found");
//     }
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

  static late String _currentPatientId; // ✅ Hold the current patient ID

  static Future<void> initialize(String patientId) async {
    _currentPatientId = patientId;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh')); // ✅ Set Riyadh Timezone

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    // ------- detects what button was pressed and performs the correct action -----------
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        int id = response.id ?? -1;
        if (id == -1) return;

        String action = response.payload ?? "";
        print("📩 Notification Action Received: $action");

        if (action == "taken") {
          _logMedicationStatus(_currentPatientId, id, "Taken");
        } else if (action == "remind_me_later") {
          _logMedicationStatus(_currentPatientId, id, "Delayed");
          _rescheduleReminder(id);
        }
      },
    );
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
      scheduledTime = scheduledTime.add(Duration(days: 1));
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
            AndroidNotificationAction(
              'taken',
              '✅ Taken',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'remind_me_later',
              '🔁 Remind Me Later',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  //------------ Firebase Integration for Medication Tracking -------------------------
  static Future<void> _logMedicationStatus(
    String patientId,
    int id,
    String status,
  ) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DateTime now = DateTime.now();
    String date = "${now.year}-${now.month}-${now.day}";

    String hour =
        (now.hour > 12) ? (now.hour - 12).toString() : now.hour.toString();
    String minute = now.minute.toString().padLeft(2, '0');
    String period = (now.hour >= 12) ? "PM" : "AM";
    String formattedTime = "$hour:$minute $period";

    // 🔥 Check the last status before logging a new one
    DatabaseEvent lastEvent = await ref
        .child("Patient")
        .child(patientId)
        .child("MedicationHistory")
        .orderByKey()
        .limitToLast(1)
        .once();

    if (lastEvent.snapshot.value != null) {
      Map<dynamic, dynamic> lastEntry =
          lastEvent.snapshot.value as Map<dynamic, dynamic>;
      String lastKey = lastEntry.keys.first;
      Map lastData = lastEntry[lastKey];

      if (lastData["status"] == "Delayed") {
        await ref
            .child("Patient")
            .child(patientId)
            .child("MedicationHistory")
            .child(lastKey)
            .update({"status": "Missed"});
        print("❌ Last medication entry updated to 'Missed'");
      }
    }

    await ref
        .child("Patient")
        .child(patientId)
        .child("MedicationHistory")
        .push()
        .set({"date": date, "time": formattedTime, "status": status});

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

    print("🔁 Reminder rescheduled for: ${newTime.toLocal()}");
  }

  //--------- Check Partial Adherence (Orange Warning) ----------------
  static Future<void> checkPartialAdherence(
    String patientId,
    String date,
  ) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref
        .child("Patient")
        .child(patientId)
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
          "🟠 Warning: Partial Adherence detected for patient $patientId on $date",
        );
        // You can trigger additional logic here
      }
    }
  }
}
