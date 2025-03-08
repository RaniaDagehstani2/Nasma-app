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

  String _doctorName = "Dr. Unknown";
  String _doctorHospital = "Unknown Hospital";
  String _doctorSpecialty = "Unknown Specialty";
  bool _showSurvey = true;
  String? _selectedActivity;
  String? _selectedBreath;
  bool showCheckIn = true;
  String activityAnswer = '';
  String breathAnswer = '';
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
        checkAndShowCheckIn(users.first['Patient_ID']);
      } else {
        print("⚠️ No patients available to display.");
      }
    });
  }

  //

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

  // Future<void> fetchTreatmentPlan(String patientId) async {
  //   print("Fetching treatment plan for patient ID: $patientId");
  //   DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
  //   DatabaseEvent patientSnapshot =
  //       await databaseRef.child('Patient').child(patientId).once();

  //   print(
  //       "Patient treatment plan data fetched: ${patientSnapshot.snapshot.value}");

  //   if (patientSnapshot.snapshot.value != null) {
  //     Map<String, dynamic> patientData =
  //         Map<String, dynamic>.from(patientSnapshot.snapshot.value as Map);

  //     String treatmentPlanId = patientData['Treatmentplan_ID'];
  //     print("Fetched treatment plan ID: $treatmentPlanId");

  //     DatabaseEvent treatmentPlanSnapshot = await databaseRef
  //         .child('TreatmentPlan')
  //         .child(treatmentPlanId)
  //         .once();

  //     print(
  //         "Treatment plan data fetched: ${treatmentPlanSnapshot.snapshot.value}");

  //     if (treatmentPlanSnapshot.snapshot.value != null) {
  //       Map<String, dynamic> treatmentPlanData = Map<String, dynamic>.from(
  //           treatmentPlanSnapshot.snapshot.value as Map);

  //       if (treatmentPlanData['isApproved'] == true) {
  //         double ACT = treatmentPlanData['ACT'] ?? 0;

  //         setState(() {
  //           if (ACT >= 20) {
  //             healthMessage = "My Asthma is Well Controlled";
  //             healthImage = 'assets/smileface.png';
  //           } else {
  //             healthMessage = "My Asthma is Worsening";
  //             healthImage = 'assets/face.png';
  //           }
  //         });

  //         String stepNum = treatmentPlanData['stepNum'].toString();
  //         print("Fetched step number: $stepNum");

  //         DatabaseEvent detailsSnapshot =
  //             await databaseRef.child('Detials').once();

  //         print("Details data fetched: ${detailsSnapshot.snapshot.value}");

  //         if (detailsSnapshot.snapshot.value != null) {
  //           Map<String, dynamic> allDetails = Map<String, dynamic>.from(
  //               detailsSnapshot.snapshot.value as Map);

  //           List<Map<String, dynamic>> filteredDetails = [];

  //           allDetails.forEach((key, value) {
  //             Map<String, dynamic> detail = Map<String, dynamic>.from(value);

  //             if (detail['stepNum'].toString() == stepNum) {
  //               print("Matching detail found for stepNum: $stepNum");

  //               String time = detail['time'];
  //               bool isPM = time.toLowerCase().contains("pm");

  //               Color cardColor = isPM ? Color(0xFF6676AA) : Color(0xFFF9FD88);
  //               String iconPath =
  //                   isPM ? "assets/night 1.png" : "assets/sun.png";
  //               Color titleColor = isPM
  //                   ? Color.fromRGBO(196, 237, 245, 1)
  //                   : Color.fromRGBO(134, 153, 218, 1);
  //               Color timeColor = isPM ? Colors.white : Colors.black;
  //               Color dosageColor = isPM ? Colors.grey[300]! : Colors.black;

  //               filteredDetails.add({
  //                 "stepNum": stepNum,
  //                 "title": detail['Name'],
  //                 "time": detail['time'],
  //                 "dosage": detail['quantity'],
  //                 "Frequancy": detail['Freq'],
  //                 "icon": iconPath,
  //                 "bgColor": cardColor,
  //                 "titleColor": titleColor,
  //                 "timeColor": timeColor,
  //                 "dosageColor": dosageColor,
  //               });
  //             }
  //           });

  //           print("Final filtered treatment details: $filteredDetails");

  //           setState(() {
  //             treatmentPlans = filteredDetails;
  //           });
  //         }
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Treatment plan is not approved yet.")),
  //         );
  //       }
  //     }
  //   }
  // }

  Future<void> fetchTreatmentPlan(String patientId) async {
    print("Fetching treatment plan for patient ID: $patientId");
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    DatabaseEvent patientSnapshot =
        await databaseRef.child('Patient').child(patientId).once();

    print(
        "Patient treatment plan data fetched: ${patientSnapshot.snapshot.value}");

    if (patientSnapshot.snapshot.value != null) {
      Map<String, dynamic> patientData =
          Map<String, dynamic>.from(patientSnapshot.snapshot.value as Map);

      String treatmentPlanId = patientData['Treatmentplan_ID'];
      print("Fetched treatment plan ID: $treatmentPlanId");

      DatabaseEvent treatmentPlanSnapshot = await databaseRef
          .child('TreatmentPlan')
          .child(treatmentPlanId)
          .once();

      print(
          "Treatment plan data fetched: ${treatmentPlanSnapshot.snapshot.value}");

      if (treatmentPlanSnapshot.snapshot.value != null) {
        Map<String, dynamic> treatmentPlanData = Map<String, dynamic>.from(
            treatmentPlanSnapshot.snapshot.value as Map);

        if (treatmentPlanData['isApproved'] == true) {
          double ACT = (treatmentPlanData['ACT'] is int)
              ? (treatmentPlanData['ACT'] as int).toDouble()
              : (treatmentPlanData['ACT'] ?? 0.0);

          setState(() {
            if (ACT >= 20) {
              healthMessage = "My Asthma is Well Controlled";
              healthImage = 'assets/smileface.png';
            } else {
              healthMessage = "My Asthma is Worsening";
              healthImage = 'assets/face.png';
            }
          });

          List<TimeOfDay> intakeTimes = [];
          if (treatmentPlanData.containsKey('intakeTimes')) {
            intakeTimes = [];
            (treatmentPlanData['intakeTimes'] as Map<dynamic, dynamic>)
                .forEach((key, value) {
              intakeTimes.add(_parseTime(value)); // Convert to TimeOfDay
            });

            // ✅ Debugging: Check if times are added
            print("🕒 Intake Times Parsed: $intakeTimes");

            // ✅ Schedule notifications
            _scheduleNotifications(intakeTimes, treatmentPlanData['name'],
                treatmentPlanData['dosage']);
          } else {
            print("🚨 No intake times found in treatment plan.");
          }

          // ✅ Schedule notifications after fetching the intake times
          _scheduleNotifications(intakeTimes, treatmentPlanData['name'],
              treatmentPlanData['dosage']);
        }
      }
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
  Future<void> showEmergencyNotification() async {
    if (uid == null) {
      print("User ID is null.");
      return;
    }

    DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    DatabaseEvent patientSnapshot =
        await databaseRef.child('Patient').child(uid!).once();

    if (patientSnapshot.snapshot.value != null) {
      Map<String, dynamic> patientData =
          Map<String, dynamic>.from(patientSnapshot.snapshot.value as Map);

      String? emergencyPhone = patientData['EM_phone']; // Get phone number

      if (emergencyPhone != null && emergencyPhone.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "🚨 Emergency message sent to: $emergencyPhone",
                style: TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    }
  }
//---------------------------------------------------------------

//--------------------Asthma Check-in-----------------------------

  Future<void> checkAndShowCheckIn(String patientID) async {
    if (patientID == null) return;

    DatabaseReference databaseRef =
        FirebaseDatabase.instance.ref().child("Questions");

    DatabaseEvent snapshot = await databaseRef.once();

    if (snapshot.snapshot.value != null) {
      Map<dynamic, dynamic> questions =
          Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);

      DateTime now = DateTime.now();

      for (var entry in questions.entries) {
        Map<String, dynamic> questionData =
            Map<String, dynamic>.from(entry.value);

        if (questionData["patientID"] == patientID &&
            questionData.containsKey("date")) {
          DateTime lastCheckIn = DateTime.parse(questionData["date"]);

          // 🎯 If the last check-in was in the same month and year, do NOT show again
          if (lastCheckIn.year == now.year && lastCheckIn.month == now.month) {
            print(
                "✅ Patient $patientID already checked in this month. Skipping.");
            return; // Exit if the check-in has already been done this month
          }
        }
      }
    }

    // 🎯 Show the check-in if not done this month
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
                          _buildOption("Very affected", "😟", Colors.red, true,
                              buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildOption("Slightly affected", "😐", Colors.yellow,
                              true, buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildOption("Not affected", "😊", Colors.blue, true,
                              buttonWidth, buttonHeight),
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
                          _buildOption("Very severe", "😟", Colors.red, false,
                              buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildOption("Mild", "😐", Colors.yellow, false,
                              buttonWidth, buttonHeight),
                          SizedBox(width: 8),
                          _buildOption("Not severe", "😊", Colors.blue, false,
                              buttonWidth, buttonHeight),
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
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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

// Updated _buildOption function to change color on selection
  Widget _buildOption(String label, String emoji, Color color, bool isActivity,
      double width, double height) {
    bool isSelected =
        isActivity ? _selectedActivity == label : _selectedBreath == label;
    bool isHovered = false; // متغير لتتبع حالة التحويم

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true), // عندما يدخل الماوس
          onExit: (_) => setState(() => isHovered = false), // عندما يخرج الماوس
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isActivity) {
                  _selectedActivity = label == "Very affected"
                      ? "Ubnormal"
                      : label == "Slightly affected"
                          ? "Moderate"
                          : "Normal";
                } else {
                  _selectedBreath = label == "Very severe"
                      ? "Ubnormal"
                      : label == "Mild"
                          ? "Moderate"
                          : "Normal";
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.8) // لون أقوى عند التحديد
                    : isHovered
                        ? color.withOpacity(0.6) // لون متوسط عند مرور الماوس
                        : color.withOpacity(
                            0.4), // لون عادي عند عدم التحديد أو التحويم
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 2),
                boxShadow: isSelected || isHovered
                    ? [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2)
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
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
      showEmergencyNotification();
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

              // Fetch data for the selected patient
              checkAndShowCheckIn(patientId!);
              fetchTreatmentPlan(patientId!);
              fetchDoctorDetails(doctorId);
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

  ///---------------------------------------------------------------------------
  Widget _buildTreatmentPlan() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TREATMENT PLAN",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.06, // Scalable font size
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenWidth * 0.04), // Scalable vertical spacing
        Container(
          height: 160, // Fixed height for the card container
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: treatmentPlans.length,
            itemBuilder: (context, index) {
              final plan = treatmentPlans[index];
              return Container(
                width: screenWidth * 0.75, // Scalable card width
                margin: EdgeInsets.only(
                    right: screenWidth * 0.04), // Scalable margin
                padding: EdgeInsets.all(screenWidth * 0.04), // Scalable padding
                decoration: BoxDecoration(
                  color: plan["bgColor"],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(plan["icon"],
                        width: screenWidth * 0.18,
                        height: screenWidth * 0.18), // Scalable icon size
                    SizedBox(width: screenWidth * 0.03), // Scalable space
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan["title"],
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045, // Scalable font size
                            fontWeight: FontWeight.bold,
                            color: plan["titleColor"],
                          ),
                        ),
                        SizedBox(
                            height: screenWidth *
                                0.02), // Scalable vertical spacing
                        Text(
                          "Time: ${plan["time"]}",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035, // Scalable font size
                            color: plan["timeColor"],
                          ),
                        ),
                        SizedBox(
                            height: screenWidth *
                                0.02), // Scalable vertical spacing
                        Text(
                          "Dosage: ${plan["dosage"]}",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035, // Scalable font size
                            color: plan["dosageColor"],
                          ),
                        ),
                        SizedBox(
                            height: screenWidth *
                                0.02), // Scalable vertical spacing
                        Text(
                          "Frequency: ${plan["Frequancy"]}",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035, // Scalable font size
                            color: plan["dosageColor"],
                          ),
                        ),
                      ],
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
              color: Color.fromARGB(255, 232, 207, 134),
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

  Widget _buildWeeklyProgress(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03, // 3% of screen width
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WEEKLY PROGRESS",
            style: GoogleFonts.poppins(
              fontSize: screenWidth *
                  0.045, // Scalable font size based on screen width
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
              height: screenHeight *
                  0.02), // Dynamically adjust space based on screen height
          Container(
            padding: EdgeInsets.all(
                screenWidth * 0.04), // Padding scaled with screen width
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
                      width: screenWidth * 0.08, // Scalable image size
                      height: screenWidth * 0.08, // Scalable image size
                    ),
                    SizedBox(
                        width: screenWidth *
                            0.02), // Spacing scaled with screen width
                    Text(
                      "Dosage Track",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth *
                            0.045, // Scalable font size based on screen width
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: screenHeight *
                        0.02), // Dynamically adjust space based on screen height
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(6, (index) {
                    bool missed = index % 3 == 0;
                    return Column(
                      children: [
                        Text(
                          "JAN ${22 + index}",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035, // Scalable font size
                          ),
                        ),
                        Image.asset(
                          missed ? 'assets/false.png' : 'assets/true.png',
                          width: screenWidth * 0.06, // Scalable image size
                          height: screenWidth * 0.06, // Scalable image size
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
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
