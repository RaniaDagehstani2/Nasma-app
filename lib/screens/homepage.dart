import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'personalInfo.dart';
import 'footer.dart';
import 'connect_patch_screen.dart';
import 'package:testtest/screens/connect_patch_screen.dart';
import 'package:testtest/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // ✅ Add this

  const HomeScreen({Key? key, required this.userId}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? selectedBoxIndex; // لتعقب المربع المحدد
  String? selectedUser;
  List<Map<String, dynamic>> users = [];
  String? uid;
  List<Map<String, dynamic>> treatmentPlans = [];
  String healthMessage = "My Asthma is Worsening";
  String healthImage = 'assets/face.png';
  String selectedAffect = ""; // Track the selected affect level
  String selectedSeverity = ""; // Track the selected severity
  String _doctorName = "Dr. Unknown";
  String _doctorHospital = "Unknown Hospital";
  String _doctorSpecialty = "Unknown Specialty";
  bool _showSurvey = true;
  String? _selectedActivity;
  String? _selectedBreath;
  bool showCheckIn = true;
  String activityAnswer = '';
  String breathAnswer = '';
  Color healthColor = const Color.fromARGB(255, 229, 212, 65);

//--------------------------------------------------footer------------
  int _selectedIndex = 0;
  String patientId = '';

  //----------------------------------------------------

  @override
  void initState() {
    super.initState();
    uid = widget.userId; // ✅ Use the passed userId
    print("✅ User ID received in HomeScreen: $uid");
    fetchUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _checkAndShowAlert(); // Call function to check if alert should be shown
  }

//------------------------------------------------------------------------------
  Future<void> fetchUserData() async {
    //uid = "1"; // Replace with actual logged-in user ID
    print("🔍 Starting fetchUserData for UID: $uid");
//---------------------------------------------------------------------------
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    Map<dynamic, dynamic> patients = {};

    // Step 1: Check if logged-in user's Patient_ID matches user_id by checking the key
    print("🛠 Checking if UID ($uid) matches a Patient_ID...");
    DatabaseEvent userPatientSnapshot = await databaseRef
        .child('Patient')
        .child(uid ?? 'default_uid') // Provide a default value if uid is null
        .once();

    if (userPatientSnapshot.snapshot.value != null) {
      print("✅ User has a matching Patient_ID!");

      var userPatientData = userPatientSnapshot.snapshot.value;
      if (userPatientData != null) {
        patients[uid] = userPatientData; // Add the patient's data to the map
      }

      // Step 2: Get all patients where Guardian_ID == Patient_ID
      print("🔄 Fetching patients with Guardian_ID = '$uid'...");
      DatabaseEvent guardianSnapshot = await databaseRef
          .child('Patient')
          .orderByChild(
              'Guardian_ID') // Search for Guardian_ID as a child property
          .equalTo(uid) // Fetch all patients with this Guardian_ID
          .once();

      if (guardianSnapshot.snapshot.value != null) {
        print("✅ Found guardian-linked patients!");
        var guardianData = guardianSnapshot.snapshot.value;
        if (guardianData is Map) {
          patients.addAll(Map<dynamic, dynamic>.from(guardianData));
        } else if (guardianData is List) {
          for (int i = 0; i < guardianData.length; i++) {
            if (guardianData[i] != null) {
              patients[i.toString()] = guardianData[i];
            }
          }
        }
      } else {
        print("⚠️ No guardian-linked patients found.");
      }
    } else {
      print("❌ User is NOT a patient, checking Guardian_ID instead...");

      // Step 3: If the user is NOT a patient, get patients where Guardian_ID == uid
      print("🔄 Fetching patients with Guardian_ID = '$uid'...");
      DatabaseEvent guardianSnapshot = await databaseRef
          .child('Patient')
          .orderByChild('Guardian_ID')
          .equalTo(uid.toString())
          .once();

      if (guardianSnapshot.snapshot.value != null) {
        print("✅ Found patients where Guardian_ID = '$uid'!");
        var guardianData = guardianSnapshot.snapshot.value;
        if (guardianData is Map) {
          patients = Map<dynamic, dynamic>.from(guardianData);
        } else if (guardianData is List) {
          for (int i = 0; i < guardianData.length; i++) {
            if (guardianData[i] != null) {
              patients[i.toString()] = guardianData[i];
            }
          }
        }
      } else {
        print("⚠️ No patients found where Guardian_ID = '$uid'.");
      }
    }

    // Step 4: Update UI with fetched patients
    print("🔄 Updating UI with fetched patients...");
    setState(() {
      users = patients.entries.map((entry) {
        Map<String, dynamic> data = Map<String, dynamic>.from(entry.value);
        return {
          'Patient_ID': entry.key.toString(),
          'Fname': data['Fname'],
          'Doctor_ID': data['Doctor_ID'],
        };
      }).toList();

      print("📋 Total patients found: ${users.length}");

      if (users.isNotEmpty) {
        patientId = users.first['Patient_ID'];
        selectedUser = users.first['Fname'];
        print("🎯 Selected first patient: $selectedUser");

        fetchDoctorDetails(users.first['Doctor_ID']);
        fetchTreatmentPlan(users.first['Patient_ID']);
        NotificationService.initialize(users.first['Patient_ID']);
        checkAndShowCheckIn(users.first['Patient_ID']);
        listenForAlerts(patientId);
      } else {
        print("⚠️ No patients available to display.");
      }
    });
  }

  Future<void> _checkAndShowAlert() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasShownAlert = prefs.getBool('hasShownAlert') ?? false;

    if (!hasShownAlert) {
      await prefs.setBool('hasShownAlert', true); // Mark alert as shown
    }
  }

  //
//-----------------------------------------------------------------

  void listenForAlerts(String patientId) async {
    if (patientId.isEmpty) {
      print("⚠️ Patient ID is empty, cannot listen for alerts.");
      return;
    }

    DatabaseReference alertsRef = FirebaseDatabase.instance
        .ref()
        .child('Patient')
        .child(patientId)
        .child('Alerts');

    // First, check for existing unseen alerts
    alertsRef.once().then((snapshot) {
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> alerts =
            Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);

        alerts.forEach((key, alertData) {
          if (alertData is Map<dynamic, dynamic>) {
            String message = alertData['message'] ?? "New alert received";
            String timestamp =
                alertData['timestamp'] ?? DateTime.now().toString();
            bool isSeen = alertData['seen'] ?? false;

            if (!isSeen) {
              showAlert(message, timestamp);
              alertsRef.child(key).update({'seen': true}).then((_) {
                print("✅ Alert marked as seen in Firebase.");
              }).catchError((error) {
                print("❌ Error updating alert status: $error");
              });
            }
          }
        });
      }
    });

    // Listen for new alerts
    alertsRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> alertData =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        String message = alertData['message'] ?? "New alert received";
        String timestamp = alertData['timestamp'] ?? DateTime.now().toString();
        bool isSeen = alertData['seen'] ?? false;

        if (!isSeen) {
          showAlert(message, timestamp);
          event.snapshot.ref.update({'seen': true}).then((_) {
            print("✅ Alert marked as seen in Firebase.");
          }).catchError((error) {
            print("❌ Error updating alert status: $error");
          });
        }
      }
    });
  }

  /// Function to show an alert on the homepage
  void showAlert(String message, String timestamp) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded edges
          ),
          elevation: 10, // Adds shadow for a modern look
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 30), // Emergency icon
              SizedBox(width: 10),
              Text(
                "Emergency Alert",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    timestamp,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Dismiss"),
            ),
          ],
        );
      },
    );
  }

//--------------------------------------------------------------------
//--------------------------------------------------------------------------
  Future<void> fetchDoctorDetails(String doctorId) async {
    print("Fetching doctor details for doctor ID: $doctorId");
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    DatabaseEvent doctorSnapshot =
        await databaseRef.child('Doctor').child(doctorId).once();

    print("Doctor data fetched: ${doctorSnapshot.snapshot.value}");

    if (doctorSnapshot.snapshot.value != null) {
      var doctorData = doctorSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (doctorData != null) {
        setState(() {
          _doctorName = "${doctorData['Fname']} ${doctorData['Lname']}";
          _doctorHospital = doctorData['Hospital'] ?? "Unknown Hospital";
          _doctorSpecialty = doctorData['Speciality'] ?? "Unknown Specialty";
        });
      } else {
        print("Doctor not found in database.");
      }
      ;
    }
  }

//----------------------------------------------------------------------------------------

  Future<void> fetchTreatmentPlan(String patientId) async {
    print("Fetching treatment plan for patient ID: $patientId");

    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    DatabaseEvent patientSnapshot =
        await databaseRef.child('Patient').child(patientId).once();

    if (patientSnapshot.snapshot.value != null) {
      Map<String, dynamic> patientData =
          Map<String, dynamic>.from(patientSnapshot.snapshot.value as Map);

      String treatmentPlanId = patientData['TreatmentPlan_ID'];
      print("Fetched treatment plan ID: $treatmentPlanId");

      DatabaseEvent treatmentPlanSnapshot = await databaseRef
          .child('TreatmentPlan')
          .child(treatmentPlanId)
          .once();

      if (treatmentPlanSnapshot.snapshot.value != null) {
        Map<String, dynamic> treatmentPlanData = Map<String, dynamic>.from(
            treatmentPlanSnapshot.snapshot.value as Map);

        if (treatmentPlanData['isApproved'] == true) {
          // code Furate---------------------------------------------------------------
          if (treatmentPlanData.containsKey('intakeTimes') &&
              treatmentPlanData.containsKey('MedicationName') &&
              treatmentPlanData.containsKey('Dosage')) {
            Map<dynamic, dynamic> intakeTimesMap =
                treatmentPlanData['intakeTimes'] as Map<dynamic, dynamic>;
            Map<dynamic, dynamic> medicationNamesMap =
                treatmentPlanData['MedicationName'] as Map<dynamic, dynamic>;
            Map<dynamic, dynamic> dosagesMap =
                treatmentPlanData['Dosage'] as Map<dynamic, dynamic>;

            intakeTimesMap.forEach((key, timeValue) {
              // ✅ Safety: Ensure key exists in medicationNamesMap & dosagesMap
              String medicationName =
                  medicationNamesMap[key]?.toString() ?? "Medication";
              String dosage = dosagesMap[key]?.toString() ?? "Dosage";

              // ✅ Safety: Ensure timeValue is String
              if (timeValue != null && timeValue is String) {
                TimeOfDay intakeTime = _parseTime(timeValue);

                // ✅ Schedule notification for this medication at this time
                _scheduleNotifications([intakeTime], medicationName, dosage);

                print(
                    "📅 Scheduled: $medicationName at $intakeTime, Dosage: $dosage");
              } else {
                print("🚨 Invalid time for key $key: $timeValue");
              }
            });
          } else {
            print(
                "🚨 Missing intakeTimes, MedicationName, or Dosage in treatmentPlanData.");
          }

          //  Furat  Code Insert Ends Here----------------------------------

          setState(() {
            String actStatus = treatmentPlanData['ACTst'] ?? 'Controlled';

            if (actStatus == 'Controlled') {
              healthMessage = "My Asthma is Well Controlled";
              healthImage = 'assets/smileface.png';
              healthColor = const Color.fromARGB(255, 89, 216, 93);
            } else if (actStatus == 'Partly Controlled') {
              healthMessage = "My Asthma is Partly Controlled";
              healthImage = 'assets/sadface.png';
              healthColor = const Color.fromARGB(255, 229, 212, 65);
            } else {
              healthMessage = "My Asthma is Uncontrolled";
              healthImage = 'assets/sadface.png';
              healthColor = const Color.fromARGB(255, 156, 43, 35);
            }
          });

          List<Map<String, dynamic>> filteredDetails = [];

          // ✅ Extract Intake Times
          List<String> intakeTimes = [];
          if (treatmentPlanData.containsKey('intakeTimes')) {
            (treatmentPlanData['intakeTimes'] as Map<dynamic, dynamic>)
                .forEach((key, value) {
              intakeTimes.add(value.toString());
            });
          }

          // ✅ Extract Medications
          List<String> medications = [];
          if (treatmentPlanData.containsKey('MedicationName')) {
            (treatmentPlanData['MedicationName'] as Map<dynamic, dynamic>)
                .forEach((key, value) {
              medications.add(value.toString());
            });
          }

          // ✅ Extract Dosages
          List<String> dosages = [];
          if (treatmentPlanData.containsKey('Dosage')) {
            (treatmentPlanData['Dosage'] as Map<dynamic, dynamic>)
                .forEach((key, value) {
              dosages.add(value.toString());
            });
          }

          // ✅ Ensure Equal Lengths (if not, fill missing data)
          int maxLength = [
            intakeTimes.length,
            medications.length,
            dosages.length
          ].reduce((a, b) => a > b ? a : b);

          while (intakeTimes.length < maxLength) intakeTimes.add("00:00 AM");
          while (medications.length < maxLength) medications.add("Unknown");
          while (dosages.length < maxLength) dosages.add("N/A");

          // ✅ Generate Cards
          for (int i = 0; i < maxLength; i++) {
            bool isPM = intakeTimes[i].toLowerCase().contains("pm");

            Color cardColor = isPM
                ? Color(0xFF6676AA)
                : Color(0xFFF9FD88); // 🎨 Night (Dark Blue) & Morning (Yellow)
            String iconPath = isPM ? "assets/night 1.png" : "assets/sun.png";
            Color titleColor = isPM
                ? Color(0xFFECF0F1)
                : Color(0xFF6676AA); // 🌙 Light Text for Dark Mode
            Color timeColor = isPM ? Colors.white : Colors.black;
            Color dosageColor = isPM ? Colors.grey[300]! : Colors.black;

            filteredDetails.add({
              "title": medications[i],
              "time": intakeTimes[i],
              "dosage": dosages[i],
              "icon": iconPath,
              "bgColor": cardColor,
              "titleColor": titleColor,
              "timeColor": timeColor,
              "dosageColor": dosageColor,
            });
          }

          setState(() {
            treatmentPlans = filteredDetails;
          });
        } else {
          print("🚨 Treatment plan is not approved.");
        }
      } else {
        print("🚨 No treatment plan found.");
      }
    } else {
      print("🚨 No patient data found.");
    }
  }

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

  void _scheduleNotifications(
      List<TimeOfDay> intakeTimes, String medicationName, String dosage) {
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

      print(
          "📅 Scheduling notification at: ${scheduledTime.toLocal()} for $medicationName");

      NotificationService.scheduleNotification(
        id: time.hour * 60 + time.minute,
        title: "Medication Reminder",
        body: "It's time to take your $medicationName ($dosage)",
        scheduledTime: scheduledTime,
      );
    }
  }

//-------------------------------------Emergncy------------------------------------
  /* Future<void> showEmergencyNotification() async {
  if (patientId.isEmpty) {
    print("Patient ID is empty.");
    return;
  }

  // Fetch the patient's alert data using their patient ID
  DatabaseReference alertRef = FirebaseDatabase.instance
      .ref()
      .child('Patient')
      .child(patientId)  // Use patientId, not uid, to fetch alerts
      .child('Alert');

  DatabaseEvent alertSnapshot = await alertRef.once();

  if (alertSnapshot.snapshot.value != null) {
    Map<String, dynamic> alertData =
        Map<String, dynamic>.from(alertSnapshot.snapshot.value as Map);

    // Example fields in Alert: type, message, timestamp
    String alertType = alertData['type'] ?? 'Unknown Alert';
    String alertMessage = alertData['message'] ?? 'Vital signs abnormal!';
    String alertTime = alertData['timestamp'] ?? '';

    print("🚨 Alert detected for patient: $alertType - $alertMessage at $alertTime");

    // Show notification to the patient using your NotificationService
    NotificationService.showNotification(
      id: 999, // Unique ID for this notification
      title: "⚠️ Emergency Alert: $alertType",
      body: alertMessage,
    );

    // Optional: Show SnackBar to inform the patient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚨 Alert: $alertType - $alertMessage",
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    });
  } else {
    print("✅ No active alerts found for patient.");
  }
}
*/

//---------------------------------------------------------------

//--------------------Asthma Check-in-----------------------------

  Future<void> checkAndShowCheckIn(String patientID) async {
    if (patientID == null) return;

    DatabaseReference patientRef =
        FirebaseDatabase.instance.ref().child("Patient").child(patientID);
    DatabaseReference questionsRef =
        FirebaseDatabase.instance.ref().child("Questions");

    // Fetch patient data
    DataSnapshot patientSnapshot = await patientRef.get();
    if (patientSnapshot.exists) {
      Map<String, dynamic> patientData =
          Map<String, dynamic>.from(patientSnapshot.value as Map);

      // Fetch the registration date (rday) for the patient
      String registrationDateString = patientData['rday'];
      DateTime registrationDate = DateTime.parse(registrationDateString);

      // Check if today is the end of the month
      DateTime today = DateTime.now();
      DateTime lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
      if (registrationDate.month == today.month &&
          registrationDate.year == today.year &&
          today != lastDayOfMonth) {
        print("❌ Not the end of the month yet.");
        return;
      }
    }

    // Fetch questions data
    DataSnapshot questionsSnapshot = await questionsRef.get();
    if (questionsSnapshot.exists) {
      Map<dynamic, dynamic> questions =
          Map<dynamic, dynamic>.from(questionsSnapshot.value as Map);

      DateTime now = DateTime.now();

      for (var entry in questions.entries) {
        Map<String, dynamic> questionData =
            Map<String, dynamic>.from(entry.value);

        if (questionData["patientID"] == patientID &&
            questionData.containsKey("date")) {
          DateTime lastCheckIn = DateTime.parse(questionData["date"]);

          if (lastCheckIn.year == now.year && lastCheckIn.month == now.month) {
            print(
                "✅ Patient $patientID already checked in this month. Skipping.");
            return; // Exit if the check-in has already been done this month
          }
        }
      }
    }

    // Show the check-in form
    _showCheckInDialog(patientID);
  }

  void _showCheckInDialog(String patientid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = MediaQuery.of(context).size.width;
              double screenHeight = MediaQuery.of(context).size.height;

              double buttonWidth = screenWidth * 0.30;
              double buttonHeight = screenHeight * 0.12;
              buttonWidth = buttonWidth.clamp(70, 70);
              buttonHeight = buttonHeight.clamp(50, 60);

              return Container(
                width: screenWidth * 0.9,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Monthly Asthma Check-In",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    Text(
                        "How much has your asthma affected your daily activities this month?"),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildClickableButton("Very affected", "😟",
                              Colors.red, true, buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildClickableButton("Slightly affected", "😐",
                              Colors.yellow, true, buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildClickableButton("Not affected", "😊",
                              Colors.blue, true, buttonWidth, buttonHeight),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                        "How severe has your shortness of breath been this month?"),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildClickableButton("Very severe", "😟", Colors.red,
                              false, buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildClickableButton("Mild", "😐", Colors.yellow,
                              false, buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildClickableButton("Not severe", "😊", Colors.blue,
                              false, buttonWidth, buttonHeight),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _saveResponsesToFirebase(patientid);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(
                            134, 153, 218, 1), // Blue submit button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text("Submit",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildClickableButton(String label, String emoji, Color color,
      bool isActivity, double width, double height) {
    bool isSelected =
        isActivity ? _selectedActivity == label : _selectedBreath == label;

    // Variable to track button press state
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) {
            // Change the color when the button is pressed
            setState(() {
              isPressed = true;
            });
          },
          onTapUp: (_) {
            // Revert the color when the press is released
            setState(() {
              isPressed = false;
            });
          },
          onTapCancel: () {
            // Revert the color if the tap is canceled
            setState(() {
              isPressed = false;
            });
          },
          onTap: () {
            setState(() {
              // Update the selected state when the button is tapped
              if (isActivity) {
                _selectedActivity = label;
              } else {
                _selectedBreath = label;
              }
            });
          },
          child: AnimatedContainer(
            duration: Duration(
                milliseconds: 150), // Shorter transition for immediate response
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isPressed
                  ? color.withOpacity(
                      0.6) // Color when pressed down (lighter opacity)
                  : isSelected
                      ? color.withOpacity(0.8) // Color when selected
                      : color.withOpacity(0.4), // Normal state color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.black
                    : Colors.transparent, // Border color when selected
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black26, // Shadow when selected
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: height * 0.35)),
                SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: height * 0.14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal, // Bold when selected
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveResponsesToFirebase(String patientID) async {
    if (_selectedActivity != null && _selectedBreath != null) {
      DatabaseReference databaseRef =
          FirebaseDatabase.instance.ref().child("Questions");

      await databaseRef.push().set({
        "patientID": patientID,
        "activity": _selectedActivity,
        "breath": _selectedBreath,
        "date":
            DateTime.now().toIso8601String(), // Save the current check-in date
      });

      // 🎯 Save the last check-in date in Firebase under the patient’s record
      await FirebaseDatabase.instance
          .ref()
          .child("Patient")
          .child(patientID)
          .update({"lastCheckIn": DateTime.now().toIso8601String()});

      setState(() {
        _showSurvey = false; // Hide survey after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Responses saved successfully!")),
      );

      // 🎯 Show emergency notification after submission
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select an option for both questions.")),
      );
    }
  }

//----------------------------------------------

  // Front-end------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Home Page"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              _buildTreatmentPlan(),
              SizedBox(height: 20),
              _buildHealthStatus(),
              SizedBox(height: 20),
              _buildWeeklyProgress(context),
              SizedBox(height: 20),
              _buildDoctorInfo(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        patientId: patientId, // ✅ Use the state variable instead
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset('assets/group.png', width: 28, height: 28),
            SizedBox(width: 8),
            Text(
              "Hi, ${selectedUser ?? "User"} 👋",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              selectedUser = value;

              // Get selected user's data
              var selectedUserData =
                  users.firstWhere((user) => user['Fname'] == value);

              patientId =
                  selectedUserData['Patient_ID']; //  Update the state variable

              var doctorId = selectedUserData['Doctor_ID'];
              NotificationService.initialize(patientId); // ✅ Add this line
              // Fetch data for the selected patient
              checkAndShowCheckIn(patientId!);
              fetchTreatmentPlan(patientId!);
              fetchDoctorDetails(doctorId);
              listenForAlerts(patientId);
            });

            print("✅ Selected Patient ID: $patientId"); // Debugging log
          },
          itemBuilder: (context) => users
              .map((user) => PopupMenuItem<String>(
                  value: user['Fname'], child: Text(user['Fname'])))
              .toList(),
          color: Colors.white,
          child: Image.asset('assets/drow_down.png', width: 20, height: 30),
        ),
      ],
    );
  }

//----------------------------------footer--------------------------
  void _onItemTapped(int index, String patientId) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    HomeScreen(userId: widget.userId)), // No patientId needed
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ConnectPatchScreen(
                    userId: widget.userId, showBackButton: true)),
          );
          break;
        case 2:
          if (patientId != null) {
            print("-------------+++++++ " + patientId);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalInfoScreen(
                  patientId: patientId!,
                  previousPage: "home",
                ),
              ),
            );
          } else {
            print(
                "❌ Error: patientId is null, cannot navigate to PersonalInfoScreen!");
          }
          break;
      }
    }
  }

  Widget _buildTreatmentPlan() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TREATMENT PLAN",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth * 0.05),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: treatmentPlans.length,
            itemBuilder: (context, index) {
              final plan = treatmentPlans[index];

              return Container(
                width: screenWidth * 0.8, // ✅ Wider card (90% of screen)
                margin: EdgeInsets.only(
                  right: screenWidth * 0.04,
                  left: index == 0
                      ? screenWidth * 0.02
                      : 0, // padding for first card
                ),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: plan["bgColor"],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset(
                      plan["icon"],
                      width: screenWidth * 0.18,
                      height: screenWidth * 0.18,
                    ),
                    SizedBox(width: screenWidth * 0.04),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan["title"],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                              color: plan["titleColor"],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            "Time: ${plan["time"]}",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              color: plan["timeColor"],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            "Dosage: ${plan["dosage"]}",
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              color: plan["dosageColor"],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStatus() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MY HEALTH",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.05, // Scalable font size
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.02), // Scalable spacing
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04), // Scalable padding
            decoration: BoxDecoration(
              color: healthColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 250, 250, 250).withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    healthMessage,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045, // Scalable font size
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // Ensures text does not overflow
                    maxLines: 2, // Limit to two lines if necessary
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // Scalable spacing
                Image.asset(
                  healthImage,
                  width: screenWidth * 0.15, // Scalable image size
                  height: screenWidth * 0.15, // Scalable image size
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfo() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MY DOCTOR",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.05, // Scalable font size
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.02), // Scalable spacing
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04), // Scalable padding
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 102, 118, 170),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/doctor.png',
                  width: screenWidth * 0.15, // Scalable image size
                  height: screenWidth * 0.15, // Scalable image size
                ),
                SizedBox(width: screenWidth * 0.03), // Scalable spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _doctorName,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04, // Scalable font size
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Hospital: $_doctorHospital",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035, // Scalable font size
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "Specialty: $_doctorSpecialty",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035, // Scalable font size
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ----function to retrieve the last 7 days of medication history from Firebase----
  Future<Map<String, String>> fetchWeeklyProgress(String patientId) async {
    if (patientId.isEmpty) return {};

    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("Patient")
        .child(patientId)
        .child("MedicationHistory");

    DateTime now = DateTime.now();
    Map<String, String> weeklyData = {};

    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      String formattedDate =
          "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

      DatabaseEvent snapshot =
          await ref.orderByChild("date").equalTo(formattedDate).once();

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        List<dynamic> statuses =
            data.values.map((e) => e['status'] as String).toList();

        if (statuses.every((s) => s == "Taken")) {
          weeklyData[formattedDate] = "Taken";
        } else if (statuses.every((s) => s == "Missed")) {
          weeklyData[formattedDate] = "Missed";
        } else {
          weeklyData[formattedDate] = "Partial";
        }
      }
    }

    return weeklyData;
  }

// ----fetches real data and updates the weekly progress ui accordingly-----
  Widget _buildWeeklyProgress(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<Map<String, String>>(
      future: fetchWeeklyProgress(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No medication history found."));
        }

        Map<String, String> weeklyProgress = snapshot.data!;

        DateTime now = DateTime.now();
        List<DateTime> last7Days = List.generate(7, (index) {
          return now.subtract(Duration(days: 6 - index));
        });

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WEEKLY PROGRESS",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/dosage.png',
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          "Dosage Track",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: last7Days.map((day) {
                        String date = DateFormat('yyyy-MM-dd').format(day);
                        String? status = weeklyProgress[date];
                        String dayName = DateFormat('E').format(day);

                        String? imagePath;
                        if (status == "Taken") {
                          imagePath = "assets/true.png";
                        } else if (status == "Missed") {
                          imagePath = "assets/false.png";
                        } else if (status == "Partial") {
                          imagePath = "assets/partially.png";
                        }

                        return Column(
                          children: [
                            Text(
                              dayName,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            imagePath != null
                                ? SizedBox(
                                    width: screenWidth * 0.06,
                                    height: screenWidth * 0.06,
                                    child: Image.asset(imagePath),
                                  )
                                : SizedBox(
                                    width: screenWidth * 0.06,
                                    height: screenWidth * 0.06,
                                    // Optional: Keep space but leave it blank
                                  ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmileyOption(String text, String imagePath, String groupValue,
      Function(String) onChanged) {
    double screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () => onChanged(text),
      child: Row(
        children: [
          Radio(
            value: text,
            groupValue: groupValue,
            onChanged: (value) {
              onChanged(value!);
            },
          ),
          Image.asset(imagePath,
              width: screenWidth * 0.08, height: screenWidth * 0.08),
          SizedBox(width: screenWidth * 0.03), // Scalable spacing
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04, // Scalable font size
            ),
          ),
        ],
      ),
    );
  }
}
