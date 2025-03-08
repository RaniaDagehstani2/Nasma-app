import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'medical_data_screen.dart';

class DependentFormScreen extends StatefulWidget {
  final String userId;

  const DependentFormScreen({super.key, required this.userId});

  @override
  _DependentFormScreenState createState() => _DependentFormScreenState();
}

class _DependentFormScreenState extends State<DependentFormScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController idController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emergencyPhoneController =
      TextEditingController();

  String? selectedDoctorId;
  List<Map<String, dynamic>> doctors = [];
  bool isValid = false;
  String? idError, nameError, phoneError, doctorError;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  void _fetchDoctors() async {
    DatabaseEvent event = await _database.child("Doctor").once();
    Map<dynamic, dynamic>? doctorData =
        event.snapshot.value as Map<dynamic, dynamic>?;

    if (doctorData != null) {
      setState(() {
        doctors = doctorData.entries.map((entry) {
          return {
            "id": entry.key,
            "Fname": entry.value["Fname"],
            "Lname": entry.value["Lname"],
            "Hospital": entry.value["Hospital"],
            "Speciality": entry.value["Speciality"],
            "Degree": entry.value["Degree"],
          };
        }).toList();
      });
    }
  }

  // void validateInputs() {
  //   String id = idController.text.trim();
  //   String firstName = firstNameController.text.trim();
  //   String lastName = lastNameController.text.trim();
  //   String phone = emergencyPhoneController.text.trim();

  //   idError = RegExp(r'^[0-9]+$').hasMatch(id)
  //       ? null
  //       : "ID must contain only numbers";
  //   nameError = RegExp(r'^[a-zA-Z]+$').hasMatch(firstName) &&
  //           RegExp(r'^[a-zA-Z]+$').hasMatch(lastName)
  //       ? null
  //       : "Name should only contain letters";
  //   phoneError = phone.length == 10 &&
  //           phone.startsWith("05") &&
  //           RegExp(r'^[0-9]+$').hasMatch(phone)
  //       ? null
  //       : "Phone must be 10 digits & start with '05'";
  //   doctorError = selectedDoctorId != null ? null : "Please select a doctor";

  //   setState(() {
  //     isValid = idError == null &&
  //         nameError == null &&
  //         phoneError == null &&
  //         doctorError == null;
  //   });
  // }
  void validateInputs() {
    String id = idController.text.trim();
    String firstName = firstNameController.text.trim();
    String lastName = firstNameController.text.trim();
    String phone = emergencyPhoneController.text.trim();

    // ✅ ID must be numbers only
    idError = RegExp(r'^[0-9]+$').hasMatch(id)
        ? null
        : "ID must contain only numbers";

    // ✅ Name must be letters only
    nameError = RegExp(r'^[a-zA-Z]+$').hasMatch(firstName) &&
            RegExp(r'^[a-zA-Z]+$').hasMatch(lastName)
        ? null
        : "Name should only contain letters";

    // ✅ Phone is optional, but if entered, it must follow rules
    if (phone.isNotEmpty) {
      phoneError = (phone.length == 10 &&
              phone.startsWith("05") &&
              RegExp(r'^[0-9]+$').hasMatch(phone))
          ? null
          : "Phone must be 10 digits & start with '05'";
    } else {
      phoneError = null; // No error if empty (optional)
    }

    // ✅ Doctor is required
    doctorError = selectedDoctorId != null ? null : "Please select a doctor";

    // ✅ "Next" button should depend on ID, Name, and Doctor (NOT Phone)
    setState(() {
      isValid = idError == null && nameError == null && doctorError == null;
    });
  }

  // void _saveDependentData() async {
  //   if (!isValid) return;
  //   String dependentId = idController.text.trim();

  //   await _database.child("Patient").child(dependentId).set({
  //     "Patient_ID": dependentId,
  //     "Fname": firstNameController.text.trim(),
  //     "Lname": lastNameController.text.trim(),
  //     "EM_phone": int.tryParse(emergencyPhoneController.text.trim()) ?? 0,
  //     "Doctor_ID": selectedDoctorId, // Store the selected doctor
  //     "Guardian_ID": widget.userId, // Set guardian to the current user
  //     "Treatmentplan_ID": "", // Fix: Ensure treatment plan is an empty string
  //   });

  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => MedicalDataScreen(userId: dependentId),
  //     ),
  //   );
  // }
  void _saveDependentData() async {
    if (!isValid) return;
    String dependentId = idController.text.trim();

    await _database.child("Patient").child(dependentId).set({
      "Patient_ID": dependentId,
      "Fname": firstNameController.text.trim(),
      "Lname": lastNameController.text.trim(),
      "EM_phone": emergencyPhoneController.text.trim().isNotEmpty
          ? int.tryParse(emergencyPhoneController.text.trim()) ?? 0
          : "", // ✅ Store empty string if phone is not entered
      "Doctor_ID": selectedDoctorId, // Required doctor selection
      "Guardian_ID": widget.userId, // Set guardian to the current user
      "Treatmentplan_ID": "", // Always empty
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalDataScreen(userId: dependentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Dependent",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: "Nunito", // Make it bold
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              onChanged: (_) => validateInputs(),
              decoration: InputDecoration(
                labelText: "ID",
                errorText: idError,
              ),
            ),
            TextField(
              controller: firstNameController,
              onChanged: (_) => validateInputs(),
              decoration: InputDecoration(
                labelText: "First Name",
                errorText: nameError,
              ),
            ),
            TextField(
              controller: lastNameController,
              onChanged: (_) => validateInputs(),
              decoration: InputDecoration(
                labelText: "Last Name",
                errorText: nameError,
              ),
            ),
            TextField(
              controller: emergencyPhoneController,
              keyboardType: TextInputType.number,
              onChanged: (_) => validateInputs(),
              decoration: InputDecoration(
                labelText: "Emergency Phone",
                errorText: phoneError,
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown to select doctor
            DropdownButtonFormField<String>(
              value: selectedDoctorId,
              hint: const Text("Select Doctor"),
              items: doctors.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc["id"],
                  child: Text(
                    "${doc["Fname"]} ${doc["Lname"]} - ${doc["Hospital"]} | ${doc["Speciality"]} | ${doc["Degree"]}",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDoctorId = value;
                  validateInputs();
                });
              },
              decoration: InputDecoration(
                errorText: doctorError,
              ),
            ),

            const SizedBox(height: 20),
            /*style: ElevatedButton.styleFrom(
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
              ), */
            ElevatedButton(
              onPressed: isValid ? _saveDependentData : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isValid ? const Color(0xFF8699DA) : const Color(0xFFB1B1B1),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 5,
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: "Nunito",
                    fontWeight:
                        FontWeight.bold), // Change to your desired color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
