// // import 'package:flutter/material.dart';

// // class HomeScreen extends StatelessWidget {
// //   const HomeScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Home")),
// //       body: const Center(child: Text("Welcome! More features coming soon.")),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'dart:convert';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String? selectedUser;
//   List<Map<String, dynamic>> users = [];
//   String? uid;
//   List<Map<String, dynamic>> treatmentPlans = [];
//   String healthMessage = "My Asthma is Worsening";
//   String healthImage = 'assets/face.png';

//   String _doctorName = "Dr. Unknown";
//   String _doctorHospital = "Unknown Hospital";
//   String _doctorSpecialty = "Unknown Specialty";
//   bool _showSurvey = true;
//   String? _selectedActivity;
//   String? _selectedBreath;
//   bool showCheckIn = true;
//   String activityAnswer = '';
//   String breathAnswer = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchUserData();
//     WidgetsBinding.instance.addPostFrameCallback((_) {});
//   }

// //------------------------------------------------------------------------------
//   Future<void> fetchUserData() async {
//     uid = '1';
//     print("Fetching user data for UID: $uid");

//     DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
//     DatabaseEvent patientSnapshot = await databaseRef
//         .child('Patient')
//         .orderByChild('user_id')
//         .equalTo(uid)
//         .once();

//     print("User data fetched: ${patientSnapshot.snapshot.value}");

//     if (patientSnapshot.snapshot.value != null) {
//       var rawData = patientSnapshot.snapshot.value;
//       Map<dynamic, dynamic> patients = {};
//       if (rawData is Map) {
//         patients = Map<dynamic, dynamic>.from(rawData);
//       } else if (rawData is List) {
//         for (int i = 0; i < rawData.length; i++) {
//           if (rawData[i] != null) {
//             patients[i.toString()] = rawData[i];
//           }
//         }
//       }

//       setState(() {
//         users = patients.entries.map((entry) {
//           Map<String, dynamic> data = Map<String, dynamic>.from(entry.value);
//           return {
//             'Patient_ID': entry.key,
//             'Fname': data['Fname'],
//             'Doctor_ID': data['Doctor_ID'],
//           };
//         }).toList();

//         if (users.isNotEmpty) {
//           selectedUser = users.first['Fname'];
//           fetchDoctorDetails(users.first['Doctor_ID']);
//           fetchTreatmentPlan(users.first['Patient_ID']);
//           _showCheckInDialog(users.first['Patient_ID']);

//           //  _showCheckInDialog(users.first['Patient_ID']); //---
//         }
//       });
//     }
//   }

//   Future<void> fetchDoctorDetails(String doctorId) async {
//     print("Fetching doctor details for doctor ID: $doctorId");
//     DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
//     DatabaseEvent doctorSnapshot =
//         await databaseRef.child('Doctor').child(doctorId).once();

//     print("Doctor data fetched: ${doctorSnapshot.snapshot.value}");

//     if (doctorSnapshot.snapshot.value != null) {
//       Map<String, dynamic> doctorData =
//           Map<String, dynamic>.from(doctorSnapshot.snapshot.value as Map);

//       setState(() {
//         _doctorName = "${doctorData['Fname']} ${doctorData['Lname']}";
//         _doctorHospital = doctorData['Hospital'];
//         _doctorSpecialty = doctorData['specialty'];
//       });
//     }
//   }

//   Future<void> fetchTreatmentPlan(String patientId) async {
//     print("Fetching treatment plan for patient ID: $patientId");
//     DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
//     DatabaseEvent patientSnapshot =
//         await databaseRef.child('Patient').child(patientId).once();

//     print(
//         "Patient treatment plan data fetched: ${patientSnapshot.snapshot.value}");

//     if (patientSnapshot.snapshot.value != null) {
//       Map<String, dynamic> patientData =
//           Map<String, dynamic>.from(patientSnapshot.snapshot.value as Map);

//       String treatmentPlanId = patientData['Treatmentplan_ID'];
//       print("Fetched treatment plan ID: $treatmentPlanId");

//       DatabaseEvent treatmentPlanSnapshot = await databaseRef
//           .child('TreatmentPlan')
//           .child(treatmentPlanId)
//           .once();

//       print(
//           "Treatment plan data fetched: ${treatmentPlanSnapshot.snapshot.value}");

//       if (treatmentPlanSnapshot.snapshot.value != null) {
//         Map<String, dynamic> treatmentPlanData = Map<String, dynamic>.from(
//             treatmentPlanSnapshot.snapshot.value as Map);

//         if (treatmentPlanData['isApproved'] == true) {
//           double ACT = treatmentPlanData['ACT'] ?? 0;

//           setState(() {
//             if (ACT >= 20) {
//               healthMessage = "My Asthma is Well Controlled";
//               healthImage = 'assets/smileface.png';
//             } else {
//               healthMessage = "My Asthma is Worsening";
//               healthImage = 'assets/face.png';
//             }
//           });

//           String stepNum = treatmentPlanData['stepNum'].toString();
//           print("Fetched step number: $stepNum");

//           DatabaseEvent detailsSnapshot =
//               await databaseRef.child('Detials').once();

//           print("Details data fetched: ${detailsSnapshot.snapshot.value}");

//           if (detailsSnapshot.snapshot.value != null) {
//             Map<String, dynamic> allDetails = Map<String, dynamic>.from(
//                 detailsSnapshot.snapshot.value as Map);

//             List<Map<String, dynamic>> filteredDetails = [];

//             allDetails.forEach((key, value) {
//               Map<String, dynamic> detail = Map<String, dynamic>.from(value);

//               if (detail['stepNum'].toString() == stepNum) {
//                 print("Matching detail found for stepNum: $stepNum");

//                 String time = detail['time'];
//                 bool isPM = time.toLowerCase().contains("pm");

//                 Color cardColor = isPM ? Color(0xFF6676AA) : Color(0xFFF9FD88);
//                 String iconPath =
//                     isPM ? "assets/night 1.png" : "assets/sun.png";
//                 Color titleColor = isPM
//                     ? Color.fromRGBO(196, 237, 245, 1)
//                     : Color.fromRGBO(134, 153, 218, 1);
//                 Color timeColor = isPM ? Colors.white : Colors.black;
//                 Color dosageColor = isPM ? Colors.grey[300]! : Colors.black;

//                 filteredDetails.add({
//                   "stepNum": stepNum,
//                   "title": detail['Name'],
//                   "time": detail['time'],
//                   "dosage": detail['quantity'],
//                   "Frequancy": detail['Freq'],
//                   "icon": iconPath,
//                   "bgColor": cardColor,
//                   "titleColor": titleColor,
//                   "timeColor": timeColor,
//                   "dosageColor": dosageColor,
//                 });
//               }
//             });

//             print("Final filtered treatment details: $filteredDetails");

//             setState(() {
//               treatmentPlans = filteredDetails;
//             });
//           }
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Treatment plan is not approved yet.")),
//           );
//         }
//       }
//     }
//   }

// //-------------------------------------------------
//   void _showCheckInDialog(String patientid) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: Center(
//             child: Text(
//               "Monthly Asthma Check-In",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                   "How much has your asthma affected your daily activities this month?"),
//               SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildOption("Very affected", "😟", Colors.red, true),
//                   _buildOption("Slightly affected", "😐", Colors.yellow, true),
//                   _buildOption("Not affected", "😊", Colors.blue, true),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Text("How severe has your shortness of breath been this month?"),
//               SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildOption("Very severe", "😟", Colors.red, false),
//                   _buildOption("Mild", "😐", Colors.yellow, false),
//                   _buildOption("Not severe", "😊", Colors.blue, false),
//                 ],
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 _saveResponsesToFirebase(patientid);
//                 Navigator.of(context).pop();
//               },
//               child: Text("Submit"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildOption(
//       String label, String emoji, Color color, bool isActivity) {
//     bool isSelected =
//         isActivity ? _selectedActivity == label : _selectedBreath == label;

//     // Current color based on selection and hover state
//     Color currentColor = isSelected ? Colors.green : color;

//     return MouseRegion(
//       onEnter: (_) {
//         setState(() {
//           // Change color on hover
//           currentColor =
//               Colors.lightBlue; // Change this to your desired hover color
//         });
//       },
//       onExit: (_) {
//         setState(() {
//           // Reset color when not hovering
//           currentColor = isSelected ? Colors.green : color;
//         });
//       },
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             if (isActivity) {
//               // Retain your original logic for setting selected activity
//               _selectedActivity = label == "Very affected"
//                   ? "Ubnormal"
//                   : label == "Slightly affected"
//                       ? "Moderate"
//                       : "Normal";
//             } else {
//               // Retain your original logic for setting selected breath
//               _selectedBreath = label == "Very severe"
//                   ? "Ubnormal"
//                   : label == "Mild"
//                       ? "Moderate"
//                       : "Normal";
//             }
//           });
//         },
//         child: AnimatedContainer(
//           duration: Duration(milliseconds: 300),
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             color: currentColor
//                 .withOpacity(0.5), // Use the current color with opacity
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//                 color: isSelected ? Colors.black : Colors.transparent,
//                 width: 2),
//             boxShadow: isSelected
//                 ? [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 10,
//                       spreadRadius: 2,
//                     ),
//                   ]
//                 : [],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(emoji, style: TextStyle(fontSize: 24)),
//               SizedBox(height: 4),
//               Text(label,
//                   textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _saveResponsesToFirebase(String patientID) async {
//     if (_selectedActivity != null && _selectedBreath != null) {
//       DatabaseReference databaseRef =
//           FirebaseDatabase.instance.ref().child("Questions");

//       await databaseRef.push().set({
//         "patientID": patientID, // users.first['Patient_ID']
//         "activity": _selectedActivity,
//         "breath": _selectedBreath,
//       });

//       setState(() {
//         _showSurvey = false; // Hide survey after saving
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Responses saved successfully!")),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Please select an option for both questions.")),
//       );
//     }
//   }

// //----------------------------------------------

//   // Front-end------------------------------------------------------
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text("Home Page"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.black),
//         titleTextStyle: GoogleFonts.poppins(
//           fontSize: 20,
//           fontWeight: FontWeight.w600,
//           color: Colors.black,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               SizedBox(height: 20),
//               _buildTreatmentPlan(),
//               SizedBox(height: 20),
//               _buildHealthStatus(),
//               SizedBox(height: 20),
//               _buildWeeklyProgress(),
//               SizedBox(height: 20),
//               _buildDoctorInfo(),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white, // Changed footer color to white
//         items: [
//           BottomNavigationBarItem(
//               icon: Image.asset('assets/home.png', width: 24, height: 24),
//               label: ''),
//           BottomNavigationBarItem(
//               icon: Image.asset('assets/device.png', width: 30, height: 30),
//               label: ''),
//           BottomNavigationBarItem(
//               icon: Image.asset('assets/user.png', width: 24, height: 24),
//               label: ''),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             Image.asset('assets/group.png', width: 28, height: 28),
//             SizedBox(width: 8),
//             Text(
//               "Hi, ${selectedUser ?? "User"} 👋",
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//         PopupMenuButton<String>(
//           // fromhere we chosse person and call method
//           onSelected: (value) {
//             setState(() {
//               selectedUser = value;
//               var selectedUserData =
//                   users.firstWhere((user) => user['Fname'] == value);
//               var patientId = selectedUserData['Patient_ID'];
//               var doctorId = selectedUserData['Doctor_ID'];

//               // Fetch all related data for the selected user
//               _showCheckInDialog(patientId);
//               fetchTreatmentPlan(patientId);

//               fetchDoctorDetails(doctorId);
//             });
//           },
//           itemBuilder: (context) => users
//               .map((user) => PopupMenuItem<String>(
//                   value: user['Fname'], child: Text(user['Fname'])))
//               .toList(),
//           color: Colors.white,
//           child: Image.asset('assets/drow_down.png', width: 20, height: 30),
//         ),
//       ],
//     );
//   }

//   Widget _buildTreatmentPlan() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "TREATMENT PLAN",
//           style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 16),
//         Container(
//           height: 160, // Increased the height of the card container
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: treatmentPlans.length,
//             itemBuilder: (context, index) {
//               final plan = treatmentPlans[index];
//               return Container(
//                 width: 280, // Increased the width of the cards
//                 margin: EdgeInsets.only(right: 16),
//                 padding:
//                     EdgeInsets.all(16), // Increased padding inside the card
//                 decoration: BoxDecoration(
//                   color: plan["bgColor"],
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Image.asset(plan["icon"],
//                         width: 70, height: 70), // Increased icon size
//                     SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           plan["title"],
//                           style: GoogleFonts.poppins(
//                             fontSize: 18, // Increased the title font size
//                             fontWeight: FontWeight.bold,
//                             color: plan["titleColor"],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           "Time: ${plan["time"]}",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14, // Increased the font size
//                             color: plan["timeColor"],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           "Dosage: ${plan["dosage"]}",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14, // Increased the font size
//                             color: plan["dosageColor"],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           "Frequency: ${plan["Frequancy"]}",
//                           style: GoogleFonts.poppins(
//                             fontSize: 14, // Increased the font size
//                             color: plan["dosageColor"],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHealthStatus() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 10.0, right: 10.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "MY HEALTH",
//             style:
//                 GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Color.fromARGB(255, 232, 207, 134),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color.fromARGB(255, 250, 250, 250).withOpacity(0.2),
//                   blurRadius: 8,
//                   offset: Offset(4, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   healthMessage,
//                   style: GoogleFonts.poppins(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white, // Set text color to white
//                   ),
//                 ),
//                 Image.asset(healthImage, width: 60, height: 60),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDoctorInfo() {
//     return Padding(
//       padding: const EdgeInsets.only(
//         left: 5.0,
//         right: 5.0,
//         bottom: 10.0,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "MY DOCTOR",
//             style:
//                 GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Color.fromARGB(255, 102, 118, 170),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                   offset: Offset(4, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Image.asset('assets/doctor.png', width: 60, height: 60),
//                 SizedBox(width: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(_doctorName,
//                         style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white)),
//                     Text("Hospital: $_doctorHospital",
//                         style: GoogleFonts.poppins(
//                             fontSize: 14, color: Colors.white70)),
//                     Text("Specialty: $_doctorSpecialty",
//                         style: GoogleFonts.poppins(
//                             fontSize: 14, color: Colors.white70)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// Widget _buildWeeklyProgress() {
//   return Padding(
//     padding: const EdgeInsets.only(
//         left: 5.0, right: 5.0), // Added left and right padding
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "WEEKLY PROGRESS",
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         SizedBox(height: 8),
//         Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Image.asset('assets/dosage.png', width: 35, height: 35),
//                   SizedBox(width: 8),
//                   Text(
//                     "Dosage Track",
//                     style: GoogleFonts.poppins(
//                         fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: List.generate(6, (index) {
//                   bool missed = index % 3 == 0;
//                   return Column(
//                     children: [
//                       Text("JAN ${22 + index}",
//                           style: GoogleFonts.poppins(fontSize: 14)),
//                       Image.asset(
//                         missed ? 'assets/false.png' : 'assets/true.png',
//                         width: 24,
//                         height: 24,
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildSmileyOption(String text, String imagePath, String groupValue,
//     Function(String) onChanged) {
//   return InkWell(
//     onTap: () => onChanged(text),
//     child: Row(
//       children: [
//         Radio(
//           value: text,
//           groupValue: groupValue,
//           onChanged: (value) {
//             onChanged(value!);
//           },
//         ),
//         Image.asset(imagePath, width: 30, height: 30),
//         SizedBox(width: 10),
//         Text(text, style: GoogleFonts.poppins(fontSize: 14)),
//       ],
//     ),
//   );
// }
