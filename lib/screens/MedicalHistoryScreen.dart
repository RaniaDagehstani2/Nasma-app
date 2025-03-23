import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String patientId;

  const MedicalHistoryScreen({super.key, required this.patientId});

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool isLoading = true;
  String bmi = "";
  String gender = "";
  bool hasAllergy = false;
  double height = 0.0;
  bool isPregnant = false;
  double weight = 0.0;
  int age = 0;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    fetchMedicalHistory();
  }

  /// ✅ Fetch Medical History Data from Firebase
  Future<void> fetchMedicalHistory() async {
    setState(() {
      isLoading = true;
    });

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

      setState(() {
        bmi = patientData['BMI'] ?? "N/A";
        gender = patientData['Gender'] ?? "Unknown";

        // ✅ Fix: Convert `Has_allergy` to boolean safely
        hasAllergy = _parseBoolean(patientData['Has_allergy']);

        // ✅ Fix: Convert `Is_pregnant` to boolean safely
        isPregnant = _parseBoolean(patientData['Is_pregnant']);

        height =
            _parseDouble(patientData['Height']); // ✅ Ensure `Height` is double
        weight =
            _parseDouble(patientData['Weight']); // ✅ Ensure `Weight` is double
        age = _calculateAge(
            patientData['Date_of_birth']); // ✅ Corrected age calculation
      });
    } catch (e) {
      debugPrint("Error fetching medical history: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  bool _parseBoolean(dynamic value) {
    if (value is bool) return value; // ✅ Already a boolean
    if (value is String)
      return value.toLowerCase() == "true"; // ✅ Convert "true" to true
    return false; // Default to false if null or invalid
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value; // ✅ Already double
    if (value is int) return value.toDouble(); // ✅ Convert int to double
    if (value is String)
      return double.tryParse(value) ?? 0.0; // ✅ Convert String to double
    return 0.0; // Default value
  }

  /// ✅ Calculate Age from Date of Birth
  int _calculateAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return 0;

    try {
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
    } catch (e) {
      debugPrint("Error parsing Date_of_birth: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          AppBar(backgroundColor: Colors.white, title: Text("Medical History")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("BMI", bmi),
                  _buildInfoRow("Gender", gender),
                  _buildInfoRow("Has Allergy", hasAllergy ? "Yes" : "No"),
                  _buildInfoRow("Height", "$height cm"), // ✅ Added Height
                  _buildInfoRow("Is Pregnant",
                      isPregnant ? "Yes" : "No"), // ✅ Fixed Pregnancy Status
                  _buildInfoRow("Weight", "$weight kg"), // ✅ Added Weight
                  _buildInfoRow("Age", "$age years"),
                ],
              ),
            ),
    );
  }

  /// ✅ Reusable Widget to Display Each Row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
