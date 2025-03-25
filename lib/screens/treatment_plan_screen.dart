import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:testtest/services/notification_service.dart';
import 'DashBoard.dart'; // Import the Dashboard screen
import 'MedicalHistoryScreen.dart'; // Import the Medical History screen

class TreatmentPlanScreen extends StatefulWidget {
  final String patientId;

  const TreatmentPlanScreen({super.key, required this.patientId});

  @override
  _TreatmentPlanScreenState createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  TextEditingController medicationController = TextEditingController();
  TextEditingController dosageController = TextEditingController();
  List<TimeOfDay> intakeTimes = [];

  bool isLoading = true;
  String patientName = "";
  int age = 0;
  int actScore = 0;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPatientAndTreatmentPlan(); // ✅ Ensure correct data fetch
    });
    NotificationService.initialize(); // Initialize notifications
  }

  /// ✅ Function to open the time picker dialog and select a time
  void _addIntakeTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        intakeTimes.add(pickedTime);
      });
    }
  }

  /// ✅ Function to remove a selected time
  void _removeIntakeTime(int index) {
    setState(() {
      intakeTimes.removeAt(index);
    });
  }

  Future<void> fetchPatientAndTreatmentPlan() async {
    setState(() {
      isLoading = true;
    });

    debugPrint("Fetching data for Patient ID: ${widget.patientId}");
    try {
      DataSnapshot patientSnapshot =
          await _databaseRef.child('Patient').child(widget.patientId).get();

      if (patientSnapshot.value == null) {
        debugPrint("No patient found with ID: ${widget.patientId}");
        setState(() {
          isLoading = false;
        });
        return;
      }

      var patientData = patientSnapshot.value as Map<dynamic, dynamic>;
      String firstName = patientData['Fname'] ?? "Unknown";
      String lastName = patientData['Lname'] ?? "";
      int fetchedAge =
          _calculateAge(patientData['Date_of_birth']); // ✅ Calculate Age

      // ✅ Update State with Correct Patient Info
      setState(() {
        patientName = "$firstName $lastName"; // ✅ Store Full Name
        age = fetchedAge; // ✅ Store Age
      });
      String? treatmentPlanId = patientData['Treatmentplan_ID'];

      if (treatmentPlanId == null || treatmentPlanId.isEmpty) {
        debugPrint("Patient has no assigned Treatment Plan.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      DataSnapshot treatmentSnapshot = await _databaseRef
          .child('TreatmentPlan')
          .child(treatmentPlanId)
          .get();

      if (treatmentSnapshot.value == null) {
        debugPrint("No treatment plan found for ID: $treatmentPlanId");
        setState(() {
          isLoading = false;
        });
        return;
      }

      var treatmentData = treatmentSnapshot.value as Map<dynamic, dynamic>;

      setState(() {
        actScore = treatmentData.containsKey('ACT') ? treatmentData['ACT'] : 0;
        medicationController.text =
            treatmentData['name'] ?? "Unknown Medication";
        dosageController.text = treatmentData['dosage'] ?? "No Dosage";

        // ✅ Parse and store intake times
        intakeTimes = [];
        if (treatmentData['intakeTimes'] is Map<dynamic, dynamic>) {
          (treatmentData['intakeTimes'] as Map<dynamic, dynamic>)
              .forEach((key, value) {
            intakeTimes.add(_parseTime(value));
          });
        }
        _scheduleNotifications(); // ✅ Schedule notifications
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  //
  void _scheduleNotifications() {
    NotificationService.cancelAll(); // ✅ Clear old notifications

    for (var time in intakeTimes) {
      DateTime now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime =
            scheduledTime.add(Duration(days: 1)); // ✅ Move to next day if past
      }

      debugPrint(
          "📅 Scheduling notification at: ${scheduledTime.toLocal()} for ${medicationController.text}");

      NotificationService.scheduleNotification(
        id: time.hour * 60 + time.minute,
        title: "Medication Reminder",
        body:
            "Time to take your ${medicationController.text} (${dosageController.text})",
        scheduledTime: scheduledTime,
      );
    }
  }

  /// ✅ Calculate Age from Date of Birth
  int _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return 0;
    List<String> parts = birthDateStr.split('/');
    if (parts.length != 3) return 0;

    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    DateTime birthDate = DateTime(year, month, day);
    DateTime today = DateTime.now();

    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// ✅ UI: Header Section
  /// ✅ UI: Header Section with Navigation Buttons
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF8699DA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Text(
            "TREATMENT PLAN RECOMMENDATION",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Name: $patientName\nAge: $age\nACT Score = $actScore",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          /// ✅ New Navigation Buttons for Dashboard & Medical History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            HealthDashboard(patientId: widget.patientId)),
                  );
                },
                child: Text(
                  "Dashboard",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            MedicalHistoryScreen(patientId: widget.patientId)),
                  );
                },
                child: Text(
                  "Medical History",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ UI: Editable Fields (Includes Time Picker)
  Widget _buildEditableFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildTextField("Medication", medicationController),
          _buildTextField("Dosage per day", dosageController),
          _buildTimePicker(),
        ],
      ),
    );
  }

  /// ✅ UI: Time Picker Widget
  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Intake Times",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 10,
            children: [
              ...List.generate(
                intakeTimes.length,
                (index) => GestureDetector(
                  onTap: () => _editIntakeTime(index),
                  child: Chip(
                    label: Text(intakeTimes[index].format(context)),
                    onDeleted: () => _removeIntakeTime(index),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addIntakeTime,
                child: Text('Add Time'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editIntakeTime(int index) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: intakeTimes[index],
    );
    if (pickedTime != null) {
      setState(() {
        intakeTimes[index] = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildEditableFields(),
                  const Spacer(),
                  _buildApproveButton(),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  /// ✅ UI: Reusable Text Field Widget
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  /// ✅ Convert String Time ("8:00 AM") to TimeOfDay

  TimeOfDay _parseTime(String time) {
    try {
      time = time.replaceAll(" ", ""); // Remove spaces
      bool isPM = time.toLowerCase().contains("pm");
      bool isAM = time.toLowerCase().contains("am");

      String cleanedTime = time.replaceAll("AM", "").replaceAll("PM", "");
      List<String> parts = cleanedTime.split(':');

      if (parts.length < 2) throw Exception("Invalid time format");

      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("🚨 Error parsing time: $time, Error: $e");
      return TimeOfDay(hour: 0, minute: 0); // Default if parsing fails
    }
  }

  Future<void> updateTreatmentPlan() async {
    try {
      DataSnapshot patientSnapshot =
          await _databaseRef.child('Patient').child(widget.patientId).get();

      if (patientSnapshot.value == null) {
        debugPrint("No patient found with this ID.");
        return;
      }

      var patientData = patientSnapshot.value as Map<dynamic, dynamic>;
      String? treatmentPlanId = patientData['Treatmentplan_ID'];

      if (treatmentPlanId == null) {
        debugPrint("No treatment plan assigned to the patient.");
        return;
      }

      DatabaseReference treatmentPlanRef =
          _databaseRef.child('TreatmentPlan').child(treatmentPlanId);

      DataSnapshot existingData = await treatmentPlanRef.get();
      if (existingData.exists && existingData.value is Map<dynamic, dynamic>) {
        var existingPlan = Map<String, Object>.from(existingData.value as Map);

        // Preserve existing data but update intakeTimes, name, dosage, and approval status
        Map<String, String> formattedTimes = {};
        for (int i = 0; i < intakeTimes.length; i++) {
          formattedTimes["timeId$i"] = intakeTimes[i].format(context);
        }

        existingPlan["intakeTimes"] = formattedTimes;
        existingPlan["name"] = medicationController.text;
        existingPlan["dosage"] = dosageController.text;
        existingPlan["isApproved"] = true;

        await treatmentPlanRef.update(existingPlan); // Firebase update
      } else {
        debugPrint("Error: Treatment plan does not exist.");
      }

      debugPrint("✅ Treatment plan updated successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Treatment plan updated successfully!")),
      );

      Navigator.pop(context, true); // Send 'true' back to trigger refresh
    } catch (e) {
      debugPrint("Error updating treatment plan: $e");
    }
  }

  /// ✅ UI: Approve Treatment Plan Button

  Widget _buildApproveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await updateTreatmentPlan();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8699DA), // ✅ Primary color
          padding: const EdgeInsets.symmetric(
              vertical: 15, horizontal: 60), // ✅ Same padding
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)), // ✅ Rounded corners
        ),
        child: const Text(
          "Approve Treatment Plan",
          style: TextStyle(
            fontSize: 19,
            fontFamily: "Nunito",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Notification Service Class (for scheduling and handling notifications)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones(); // Ensure timezone support

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == "taken") {
        print("✅ Medication Taken");
      } else if (response.payload == "remind_me_later") {
        print("🔁 Reminder Rescheduled");
        _rescheduleReminder();
      }
    });
  }

  static Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledTime}) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true, // Keep it persistent
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

  static Future<void> _rescheduleReminder() async {
    // Reschedule after 15 minutes
    DateTime newTime = DateTime.now().add(Duration(minutes: 15));
    await scheduleNotification(
      id: 999,
      title: "Medication Reminder",
      body: "It's time to take your medication!",
      scheduledTime: newTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
