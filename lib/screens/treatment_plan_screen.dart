// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:testtest/services/notification_service.dart';
// import 'DashBoard.dart'; // Import the Dashboard screen
// import 'MedicalHistoryScreen.dart'; // Import the Medical History screen

// class TreatmentPlanScreen extends StatefulWidget {
//   final String patientId;

//   const TreatmentPlanScreen({super.key, required this.patientId});

//   @override
//   _TreatmentPlanScreenState createState() => _TreatmentPlanScreenState();
// }

// class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
//   TextEditingController medicationController = TextEditingController();
//   TextEditingController dosageController = TextEditingController();
//   List<TimeOfDay> intakeTimes = [];

//   bool isLoading = true;
//   String patientName = "";
//   int age = 0;
//   int actScore = 0;

//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       fetchPatientAndTreatmentPlan(); // ✅ Ensure correct data fetch
//     });
//     NotificationService.initialize(); // Initialize notifications
//   }

//   /// ✅ Function to open the time picker dialog and select a time
//   void _addIntakeTime() async {
//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//     if (pickedTime != null) {
//       setState(() {
//         intakeTimes.add(pickedTime);
//       });
//     }
//   }

//   /// ✅ Function to remove a selected time
//   void _removeIntakeTime(int index) {
//     setState(() {
//       intakeTimes.removeAt(index);
//     });
//   }

//   Future<void> fetchPatientAndTreatmentPlan() async {
//     setState(() {
//       isLoading = true;
//     });

//     debugPrint("Fetching data for Patient ID: ${widget.patientId}");
//     try {
//       DataSnapshot patientSnapshot =
//           await _databaseRef.child('Patient').child(widget.patientId).get();

//       if (patientSnapshot.value == null) {
//         debugPrint("No patient found with ID: ${widget.patientId}");
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }

//       var patientData = patientSnapshot.value as Map<dynamic, dynamic>;
//       String firstName = patientData['Fname'] ?? "Unknown";
//       String lastName = patientData['Lname'] ?? "";
//       int fetchedAge =
//           _calculateAge(patientData['Date_of_birth']); // ✅ Calculate Age

//       // ✅ Update State with Correct Patient Info
//       setState(() {
//         patientName = "$firstName $lastName"; // ✅ Store Full Name
//         age = fetchedAge; // ✅ Store Age
//       });
//       String? treatmentPlanId = patientData['Treatmentplan_ID'];

//       if (treatmentPlanId == null || treatmentPlanId.isEmpty) {
//         debugPrint("Patient has no assigned Treatment Plan.");
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }

//       DataSnapshot treatmentSnapshot = await _databaseRef
//           .child('TreatmentPlan')
//           .child(treatmentPlanId)
//           .get();

//       if (treatmentSnapshot.value == null) {
//         debugPrint("No treatment plan found for ID: $treatmentPlanId");
//         setState(() {
//           isLoading = false;
//         });
//         return;
//       }

//       var treatmentData = treatmentSnapshot.value as Map<dynamic, dynamic>;

//       setState(() {
//         actScore = treatmentData.containsKey('ACT') ? treatmentData['ACT'] : 0;
//         medicationController.text =
//             treatmentData['name'] ?? "Unknown Medication";
//         dosageController.text = treatmentData['dosage'] ?? "No Dosage";

//         // ✅ Parse and store intake times
//         intakeTimes = [];
//         if (treatmentData['intakeTimes'] is Map<dynamic, dynamic>) {
//           (treatmentData['intakeTimes'] as Map<dynamic, dynamic>)
//               .forEach((key, value) {
//             intakeTimes.add(_parseTime(value));
//           });
//         }
//         _scheduleNotifications(); // ✅ Schedule notifications
//       });
//     } catch (e) {
//       debugPrint("Error fetching data: $e");
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   //
//   void _scheduleNotifications() {
//     NotificationService.cancelAll(); // ✅ Clear old notifications

//     for (var time in intakeTimes) {
//       DateTime now = DateTime.now();
//       DateTime scheduledTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         time.hour,
//         time.minute,
//       );

//       if (scheduledTime.isBefore(now)) {
//         scheduledTime =
//             scheduledTime.add(Duration(days: 1)); // ✅ Move to next day if past
//       }

//       debugPrint(
//           "📅 Scheduling notification at: ${scheduledTime.toLocal()} for ${medicationController.text}");

//       NotificationService.scheduleNotification(
//         id: time.hour * 60 + time.minute,
//         title: "Medication Reminder",
//         body:
//             "Time to take your ${medicationController.text} (${dosageController.text})",
//         scheduledTime: scheduledTime,
//       );
//     }
//   }

//   /// ✅ Calculate Age from Date of Birth
//   int _calculateAge(String? birthDateStr) {
//     if (birthDateStr == null) return 0;
//     List<String> parts = birthDateStr.split('/');
//     if (parts.length != 3) return 0;

//     int day = int.parse(parts[0]);
//     int month = int.parse(parts[1]);
//     int year = int.parse(parts[2]);

//     DateTime birthDate = DateTime(year, month, day);
//     DateTime today = DateTime.now();

//     int age = today.year - birthDate.year;
//     if (today.month < birthDate.month ||
//         (today.month == birthDate.month && today.day < birthDate.day)) {
//       age--;
//     }

//     return age;
//   }

//   /// ✅ UI: Header Section
//   /// ✅ UI: Header Section with Navigation Buttons
//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 260,
//       decoration: BoxDecoration(
//         color: const Color(0xFF8699DA),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(40),
//           bottomRight: Radius.circular(40),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 40),
//           Text(
//             "TREATMENT PLAN RECOMMENDATION",
//             style: GoogleFonts.poppins(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               letterSpacing: 1,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 10),
//           Text(
//             "Name: $patientName\nAge: $age\nACT Score = $actScore",
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.white,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),

//           /// ✅ New Navigation Buttons for Dashboard & Medical History
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             HealthDashboard(patientId: widget.patientId)),
//                   );
//                 },
//                 child: Text(
//                   "Dashboard",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: const Color.fromARGB(255, 255, 255, 255),
//                   ),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             MedicalHistoryScreen(patientId: widget.patientId)),
//                   );
//                 },
//                 child: Text(
//                   "Medical History",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: const Color.fromARGB(255, 255, 255, 255),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// ✅ UI: Editable Fields (Includes Time Picker)
//   Widget _buildEditableFields() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         children: [
//           _buildTextField("Medication", medicationController),
//           _buildTextField("Dosage per day", dosageController),
//           _buildTimePicker(),
//         ],
//       ),
//     );
//   }

//   /// ✅ UI: Time Picker Widget
//   Widget _buildTimePicker() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Intake Times",
//             style:
//                 GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 5),
//           Wrap(
//             spacing: 10,
//             children: [
//               ...List.generate(
//                 intakeTimes.length,
//                 (index) => GestureDetector(
//                   onTap: () => _editIntakeTime(index),
//                   child: Chip(
//                     label: Text(intakeTimes[index].format(context)),
//                     onDeleted: () => _removeIntakeTime(index),
//                   ),
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: _addIntakeTime,
//                 child: Text('Add Time'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void _editIntakeTime(int index) async {
//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: intakeTimes[index],
//     );
//     if (pickedTime != null) {
//       setState(() {
//         intakeTimes[index] = pickedTime;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: isLoading
//             ? Center(child: CircularProgressIndicator())
//             : Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildHeader(context),
//                   const SizedBox(height: 20),
//                   _buildEditableFields(),
//                   const Spacer(),
//                   _buildApproveButton(),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//       ),
//     );
//   }

//   /// ✅ UI: Reusable Text Field Widget
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(),
//         ),
//       ),
//     );
//   }

//   /// ✅ Convert String Time ("8:00 AM") to TimeOfDay

//   TimeOfDay _parseTime(String time) {
//     try {
//       time = time.replaceAll(" ", ""); // Remove spaces
//       bool isPM = time.toLowerCase().contains("pm");
//       bool isAM = time.toLowerCase().contains("am");

//       String cleanedTime = time.replaceAll("AM", "").replaceAll("PM", "");
//       List<String> parts = cleanedTime.split(':');

//       if (parts.length < 2) throw Exception("Invalid time format");

//       int hour = int.tryParse(parts[0]) ?? 0;
//       int minute = int.tryParse(parts[1]) ?? 0;

//       if (isPM && hour != 12) hour += 12;
//       if (isAM && hour == 12) hour = 0;

//       return TimeOfDay(hour: hour, minute: minute);
//     } catch (e) {
//       print("🚨 Error parsing time: $time, Error: $e");
//       return TimeOfDay(hour: 0, minute: 0); // Default if parsing fails
//     }
//   }

//   Future<void> updateTreatmentPlan() async {
//     try {
//       DataSnapshot patientSnapshot =
//           await _databaseRef.child('Patient').child(widget.patientId).get();

//       if (patientSnapshot.value == null) {
//         debugPrint("No patient found with this ID.");
//         return;
//       }

//       var patientData = patientSnapshot.value as Map<dynamic, dynamic>;
//       String? treatmentPlanId = patientData['Treatmentplan_ID'];

//       if (treatmentPlanId == null) {
//         debugPrint("No treatment plan assigned to the patient.");
//         return;
//       }

//       DatabaseReference treatmentPlanRef =
//           _databaseRef.child('TreatmentPlan').child(treatmentPlanId);

//       DataSnapshot existingData = await treatmentPlanRef.get();
//       if (existingData.exists && existingData.value is Map<dynamic, dynamic>) {
//         var existingPlan = Map<String, Object>.from(existingData.value as Map);

//         // Preserve existing data but update intakeTimes, name, dosage, and approval status
//         Map<String, String> formattedTimes = {};
//         for (int i = 0; i < intakeTimes.length; i++) {
//           formattedTimes["timeId$i"] = intakeTimes[i].format(context);
//         }

//         existingPlan["intakeTimes"] = formattedTimes;
//         existingPlan["name"] = medicationController.text;
//         existingPlan["dosage"] = dosageController.text;
//         existingPlan["isApproved"] = true;

//         await treatmentPlanRef.update(existingPlan); // Firebase update
//       } else {
//         debugPrint("Error: Treatment plan does not exist.");
//       }

//       debugPrint("✅ Treatment plan updated successfully!");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Treatment plan updated successfully!")),
//       );

//       Navigator.pop(context, true); // Send 'true' back to trigger refresh
//     } catch (e) {
//       debugPrint("Error updating treatment plan: $e");
//     }
//   }

//   /// ✅ UI: Approve Treatment Plan Button

//   Widget _buildApproveButton() {
//     return Center(
//       child: ElevatedButton(
//         onPressed: () async {
//           await updateTreatmentPlan();
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF8699DA), // ✅ Primary color
//           padding: const EdgeInsets.symmetric(
//               vertical: 15, horizontal: 60), // ✅ Same padding
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30)), // ✅ Rounded corners
//         ),
//         child: const Text(
//           "Approve Treatment Plan",
//           style: TextStyle(
//             fontSize: 19,
//             fontFamily: "Nunito",
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Notification Service Class (for scheduling and handling notifications)
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:testtest/services/notification_service.dart';
import 'DashBoard.dart';
import 'MedicalHistoryScreen.dart';

class TreatmentPlanScreen extends StatefulWidget {
  final String patientId;

  const TreatmentPlanScreen({super.key, required this.patientId});

  @override
  _TreatmentPlanScreenState createState() => _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState extends State<TreatmentPlanScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  String patientName = "";
  int age = 0;
  int actScore = 0;
  bool isLoading = true;

  List<TimeOfDay> intakeTimes = [];

  Map<String, dynamic> mainPlan = {};
  Map<String, dynamic> altPlan = {};
  String selectedOption = "main";

  Map<String, TextEditingController> nameControllers1 = {};
  Map<String, TextEditingController> nameControllers2 = {};
  Map<String, TextEditingController> dosageControllers1 = {};
  Map<String, TextEditingController> dosageControllers2 = {};
  Map<String, TextEditingController> frequencyControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPatientAndTreatmentPlan();
    });
    NotificationService.initialize(widget.patientId); // ✅ NEW
  }

  Future<void> fetchPatientAndTreatmentPlan() async {
    setState(() => isLoading = true);

    try {
      DataSnapshot patientSnapshot =
          await _databaseRef.child('Patient').child(widget.patientId).get();
      if (patientSnapshot.value == null) return;
      if (patientSnapshot.value == null || patientSnapshot.value is! Map)
        return;
      var patientData = Map<String, dynamic>.from(patientSnapshot.value as Map);

      String fullName = "${patientData['Fname']} ${patientData['Lname']}";
      int fetchedAge = _calculateAge(patientData['Date_of_birth']);
      // String? treatmentPlanId = patientData['TreatmentPlan_ID'];
      String? treatmentPlanId = patientData['TreatmentPlan_ID'];

      if (treatmentPlanId == null) return;

      DataSnapshot treatmentSnapshot = await _databaseRef
          .child('TreatmentPlan')
          .child(treatmentPlanId)
          .get();
      if (!treatmentSnapshot.exists) return;
      var treatmentData = treatmentSnapshot.value as Map;
      String stepNum = treatmentData['stepNum'] ?? '';
      debugPrint("🧪 Step Num: $stepNum");
      if (stepNum.isEmpty) return;

      DataSnapshot stepSnapshot =
          await _databaseRef.child('MedicalStep').child(stepNum).get();

      if (stepSnapshot.value == null || stepSnapshot.value is! Map) return;
      if (stepSnapshot.value == null) {
        debugPrint("❌ Step not found for stepNum: $stepNum");
        return;
      }

      var stepData = Map<String, dynamic>.from(stepSnapshot.value as Map);

      setState(() {
        patientName = fullName;
        age = fetchedAge;
        actScore = (treatmentData['ACT'] ?? 0)
            .toDouble()
            .round(); // or use toStringAsFixed(1) if you want 1 decimal

        // ✅ Extract plans
        mainPlan = {
          'MedicationName1': stepData['MedicationName']?['MainName1'] ?? '',
          'MedicationName2': stepData['MedicationName']?['MainName2'] ?? '',
          'Dosage1': stepData['Dosage']?['MainInhale1'] ?? '',
          'Dosage2': stepData['Dosage']?['MainInhale2'] ?? '',
          'Frequency': stepData['Frequency']?['MainFreq1'] ?? '',
        };

        altPlan = {
          'MedicationName1': stepData['MedicationName']?['AltName1'] ?? '',
          'MedicationName2': stepData['MedicationName']?['AltName2'] ??
              '', // <== could be null!
          'Dosage1': stepData['Dosage']?['AltInhale1'] ?? '',
          'Dosage2':
              stepData['Dosage']?['AltInhale2']?.toString() ?? '', // safe
          'Frequency1': stepData['Frequency']?['AltFreq1']?.toString() ?? '',
          'Frequency2': stepData['Frequency']?['AltFreq2']?.toString() ?? '',
        };

        // ✅ Setup controllers for plan fields
        nameControllers1 = {
          'main': TextEditingController(text: mainPlan['MedicationName1']),
          'alt1': TextEditingController(text: altPlan['MedicationName1']),
          'alt2': TextEditingController(text: altPlan['MedicationName2']),
        };

        nameControllers2 = {
          'main': TextEditingController(text: mainPlan['MedicationName2']),
          'alt1': TextEditingController(), // Optional if no MedName2 for alt1
          'alt2': TextEditingController(), // Optional if no MedName2 for alt2
        };

        dosageControllers1 = {
          'main': TextEditingController(text: mainPlan['Dosage1']),
          'alt1': TextEditingController(text: altPlan['Dosage1']),
          'alt2': TextEditingController(text: altPlan['Dosage2']),
        };

        dosageControllers2 = {
          'main': TextEditingController(text: mainPlan['Dosage2']),
          'alt1': TextEditingController(), // Optional if no Dosage2 for alt1
          'alt2': TextEditingController(), // Optional if no Dosage2 for alt2
        };

        frequencyControllers = {
          'main': TextEditingController(text: mainPlan['Frequency']),
          'alt1': TextEditingController(text: altPlan['Frequency1']),
          'alt2': TextEditingController(text: altPlan['Frequency2']),
        };

        // ✅ Parse and set intakeTimes
        intakeTimes = [];
        if (treatmentData['intakeTimes'] is Map) {
          (treatmentData['intakeTimes'] as Map).forEach((_, value) {
            intakeTimes.add(_parseTime(value));
          });
        }

        _scheduleNotifications();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateTreatmentPlan() async {
    print("🟢 Approve button pressed");
    try {
      DataSnapshot patientSnapshot =
          await _databaseRef.child('Patient').child(widget.patientId).get();
      if (patientSnapshot.value == null || patientSnapshot.value is! Map)
        return;
      var patientData = Map<String, dynamic>.from(patientSnapshot.value as Map);

      String treatmentPlanId = patientData['TreatmentPlan_ID'];

      DatabaseReference treatmentPlanRef =
          _databaseRef.child('TreatmentPlan').child(treatmentPlanId);

      Map<String, String> formattedTimes = {};
      for (int i = 0; i < intakeTimes.length; i++) {
        formattedTimes["timeId$i"] = intakeTimes[i].format(context);
      }

      await treatmentPlanRef.update({
        "MedicationName": {
          "name1": nameControllers1[selectedOption]?.text ?? "",
          "name2": nameControllers2[selectedOption]?.text ?? "",
        },
        "Dosage": {
          "inhale1": dosageControllers1[selectedOption]?.text ?? "",
          "inhale2": dosageControllers2[selectedOption]?.text ?? "",
        },
        "Frequency": frequencyControllers[selectedOption]?.text ?? "",
        "intakeTimes": formattedTimes,
        "isApproved": true,
        "lastUpdated": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Treatment plan updated successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Update failed: $e");
    }
  }

  Widget _buildPlanOption(
    String optionType,
    TextEditingController name1Ctrl,
    TextEditingController name2Ctrl,
    TextEditingController dosage1Ctrl,
    TextEditingController dosage2Ctrl,
    TextEditingController freqCtrl,
  ) {
    bool isSelected = selectedOption == optionType;
    return GestureDetector(
      onTap: () => setState(() => selectedOption = optionType),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF8699DA) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${optionType == "main" ? "Main" : "Alternative"} Plan",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField("Medication Name 1", name1Ctrl),
            _buildTextField("Dosage 1", dosage1Ctrl),
            if (name2Ctrl.text.isNotEmpty || dosage2Ctrl.text.isNotEmpty)
              Column(
                children: [
                  _buildTextField("Medication Name 2", name2Ctrl),
                  _buildTextField("Dosage 2", dosage2Ctrl),
                ],
              ),
            _buildTextField("Frequency", freqCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFields() {
    List<Widget> options = [];

    if (mainPlan['MedicationName1'].toString().isNotEmpty) {
      options.add(_buildPlanOption(
        "main",
        nameControllers1['main']!,
        nameControllers2['main']!,
        dosageControllers1['main']!,
        dosageControllers2['main']!,
        frequencyControllers['main']!,
      ));
    }

    if (altPlan['MedicationName1'].toString().isNotEmpty) {
      options.add(_buildPlanOption(
        "alt1",
        nameControllers1['alt1'] ?? TextEditingController(),
        nameControllers2['alt1'] ?? TextEditingController(),
        dosageControllers1['alt1'] ?? TextEditingController(),
        dosageControllers2['alt1'] ?? TextEditingController(),
        frequencyControllers['alt1'] ?? TextEditingController(),
      ));
    }

    if ((altPlan['MedicationName2'] ?? '').toString().isNotEmpty ||
        (altPlan['Dosage2'] ?? '').toString().isNotEmpty ||
        (altPlan['Frequency2'] ?? '').toString().isNotEmpty) {
      options.add(_buildPlanOption(
        "alt2",
        nameControllers1['alt2'] ??= TextEditingController(),
        nameControllers2['alt2'] ??= TextEditingController(),
        dosageControllers1['alt2'] ??= TextEditingController(),
        dosageControllers2['alt2'] ??= TextEditingController(),
        frequencyControllers['alt2'] ??= TextEditingController(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Please review and choose one of the following recommended treatment options. You may also modify the details if necessary before approval.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...options,
          const SizedBox(height: 10),
          _buildTimePicker(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Intake Times",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
                    backgroundColor: const Color.fromARGB(
                        255, 246, 249, 255), // Light blue-ish background
                    // backgroundColor:
                    //     Color(0xFFF1F3F6), // soft neutral gray-blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none, // Removes the black border
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _addIntakeTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color.fromARGB(255, 144, 161, 215), // Your primary color
                  foregroundColor: Colors.white, // Text/icon color
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Add Time'),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  void _removeIntakeTime(int index) {
    setState(() {
      intakeTimes.removeAt(index);
    });
  }

  void _scheduleNotifications() {
    NotificationService.cancelAll();
    for (var time in intakeTimes) {
      DateTime now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledTime.isBefore(now))
        scheduledTime = scheduledTime.add(Duration(days: 1));

      NotificationService.scheduleNotification(
        id: time.hour * 60 + time.minute,
        title: "Medication Reminder",
        body:
            "Time to take your ${nameControllers1[selectedOption]?.text} (${dosageControllers1[selectedOption]?.text})",
        scheduledTime: scheduledTime,
      );
    }
  }

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

  TimeOfDay _parseTime(String time) {
    try {
      time = time.replaceAll(" ", "");
      bool isPM = time.toLowerCase().contains("pm");
      bool isAM = time.toLowerCase().contains("am");
      String cleanedTime = time.replaceAll("AM", "").replaceAll("PM", "");
      List<String> parts = cleanedTime.split(':');
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return TimeOfDay(hour: 0, minute: 0);
    }
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Container(
  //     width: MediaQuery.of(context).size.width,
  //     height: 260,
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF8699DA),
  //       borderRadius: const BorderRadius.only(
  //         bottomLeft: Radius.circular(40),
  //         bottomRight: Radius.circular(40),
  //       ),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const SizedBox(height: 40),
  //         Text(
  //           "TREATMENT PLAN RECOMMENDATION",
  //           style: GoogleFonts.poppins(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //             letterSpacing: 1,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 10),
  //         Text(
  //           "Name: $patientName\nAge: $age\nACT Score = $actScore",
  //           style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             TextButton(
  //               onPressed: () => Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                     builder: (_) => HealthDashboard(
  //                           patientId: widget.patientId,
  //                         )),
  //               ),
  //               child: Text(
  //                 "Dashboard",
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //             TextButton(
  //               onPressed: () => Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (_) => MedicalHistoryScreen(
  //                     patientId: widget.patientId,
  //                   ),
  //                 ),
  //               ),
  //               child: Text(
  //                 "Medical History",
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width, // ✅ Full width
      height: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF8699DA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          /// ✅ Back button
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// ✅ Main header content centered
          Align(
            alignment: Alignment.center,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HealthDashboard(
                            patientId: widget.patientId,
                          ),
                        ),
                      ),
                      child: Text(
                        "Dashboard",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicalHistoryScreen(
                            patientId: widget.patientId,
                          ),
                        ),
                      ),
                      child: Text(
                        "Medical History",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApproveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: updateTreatmentPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8699DA),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16), // Optional padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildEditableFields(),
                    const SizedBox(height: 30), // Replaces Spacer()
                    _buildApproveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
