import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'patient_form_screen.dart';
import 'dependent_form_screen.dart';
//import 'home_screen.dart';
import 'homepage.dart';

class SignUpNextScreen extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;

  const SignUpNextScreen({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  @override
  _SignUpNextScreenState createState() => _SignUpNextScreenState();
}

class _SignUpNextScreenState extends State<SignUpNextScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool isPatientAdded = false;
  Map<dynamic, dynamic>? dependents;

  @override
  void initState() {
    super.initState();
    _checkIfPatientExists();
    _loadDependents();
  }

  void _checkIfPatientExists() async {
    DatabaseEvent event =
        await _database.child("Patient").child(widget.userId).once();
    setState(() {
      isPatientAdded = event.snapshot.value != null;
    });
  }

  void _loadDependents() async {
    DatabaseEvent event = await _database
        .child("Patient")
        .orderByChild("Guardian_ID")
        .equalTo(widget.userId)
        .once();
    if (event.snapshot.value != null) {
      setState(() {
        dependents = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      });
    } else {
      setState(() {
        dependents = {};
      });
    }
  }

  void _addPatient() {
    if (!isPatientAdded) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientFormScreen(
            userId: widget.userId,
            firstName: widget.firstName,
            lastName: widget.lastName,
            isDependent: false,
          ),
        ),
      ).then((_) {
        _checkIfPatientExists();
        _loadDependents();
      });
    }
  }

  void _addDependent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DependentFormScreen(userId: widget.userId),
      ),
    ).then((_) => _loadDependents());
  }

  // @override
  // Widget build(BuildContext context) {
  //   bool canStart =
  //       isPatientAdded || (dependents != null && dependents!.isNotEmpty);

  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text("Sign Up"),
  //       automaticallyImplyLeading: false, // This removes the back button
  //     ),
  //     // appBar: AppBar(title: const Text("Sign Up")),
  //     body: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text("I'm Patient"),
  //           const SizedBox(height: 5),
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: isPatientAdded
  //                     ? Container(
  //                         padding: const EdgeInsets.all(12),
  //                         decoration: BoxDecoration(
  //                           border: Border.all(color: const Color(0xFF8699DA)),
  //                           borderRadius: BorderRadius.circular(15),
  //                           color: Colors.white,
  //                         ),
  //                         child: Text(
  //                           "${widget.firstName} ${widget.lastName}",
  //                           style: const TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                           textAlign: TextAlign.center,
  //                         ),
  //                       )
  //                     : Container(),
  //               ),
  //               const SizedBox(width: 10),
  //               IconButton(
  //                 icon: const Icon(Icons.add, color: Colors.white, size: 20),
  //                 onPressed: isPatientAdded ? null : _addPatient,
  //                 style: IconButton.styleFrom(
  //                   backgroundColor:
  //                       isPatientAdded ? Colors.grey : const Color(0xFF8699DA),
  //                   minimumSize: const Size(100, 30),
  //                   padding: EdgeInsets.zero,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 20),
  //           const Text("I've Dependent"),
  //           const SizedBox(height: 5),
  //           Row(
  //             children: [
  //               Expanded(child: Container()),
  //               const SizedBox(width: 10),
  //               IconButton(
  //                 icon: const Icon(Icons.add, color: Colors.white, size: 20),
  //                 onPressed: _addDependent,
  //                 style: IconButton.styleFrom(
  //                   backgroundColor: const Color(0xFF8699DA),
  //                   minimumSize: const Size(100, 30),
  //                   padding: EdgeInsets.zero,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 20),
  //           dependents != null && dependents!.isNotEmpty
  //               ? Column(
  //                   children: dependents!.entries.map((entry) {
  //                     return Container(
  //                       width: double.infinity,
  //                       padding: const EdgeInsets.all(12),
  //                       margin: const EdgeInsets.symmetric(vertical: 5),
  //                       decoration: BoxDecoration(
  //                         border: Border.all(color: Colors.blue),
  //                         borderRadius: BorderRadius.circular(8),
  //                         color: Colors.white,
  //                       ),
  //                       child: Center(
  //                         child: Text(
  //                           "${entry.value["Fname"]} ${entry.value["Lname"]}",
  //                           style: const TextStyle(
  //                               fontSize: 16, fontWeight: FontWeight.bold),
  //                         ),
  //                       ),
  //                     );
  //                   }).toList(),
  //                 )
  //               : const Text("No dependents added yet."),
  //           const SizedBox(height: 100),
  //           Center(
  //             child: ElevatedButton(
  //               onPressed: canStart
  //                   ? () {
  //                       Navigator.pushReplacement(
  //                         context,
  //                         MaterialPageRoute(builder: (context) => HomeScreen()),
  //                       );
  //                     }
  //                   : null,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: canStart
  //                     ? const Color(0xFF8699DA)
  //                     : const Color(0xFFB1B1B1),
  //                 padding:
  //                     const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
  //                 shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(24)),
  //                 elevation: 5,
  //               ),
  //               child: const Text("Start",
  //                   style: TextStyle(
  //                       fontSize: 18,
  //                       color: Colors.white,
  //                       fontFamily: "Nunito",
  //                       fontWeight: FontWeight.bold)),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    bool canStart =
        isPatientAdded || (dependents != null && dependents!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: "Nunito", // Make it bold
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === "I'm Patient" Section ===
            const Text("I'm Patient"),
            const SizedBox(height: 5),
            if (!isPatientAdded)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: _addPatient,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF8699DA),
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "You can add your information as a patient",
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF8699DA)),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: Text(
                  "${widget.firstName} ${widget.lastName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // === "I've Dependent" Section ===
            const Text("I've Dependent"),
            const SizedBox(height: 10),

            // Display added dependents first (each name gets a box like the patient box)
            if (dependents != null && dependents!.isNotEmpty)
              Column(
                children: dependents!.entries.map((entry) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF8699DA)),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        "${entry.value["Fname"]} ${entry.value["Lname"]}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Show "You can add dependents" text + Button RIGHT UNDER last dependent
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: _addDependent,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF8699DA),
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "You can add dependents",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 70),

            // Start Button
            Center(
              child: ElevatedButton(
                onPressed: canStart
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  HomeScreen(userId: widget.userId)),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canStart
                      ? const Color(0xFF8699DA)
                      : const Color(0xFFB1B1B1),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 5,
                ),
                child: const Text("Start",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: "Nunito",
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
