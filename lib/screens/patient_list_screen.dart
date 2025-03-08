import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testtest/screens/treatment_plan_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? doctorId;
  List<Map<String, dynamic>> patients = [];
  String currentFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchDoctorPatients();
  }

  void _fetchDoctorPatients() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Fetch Doctor List
    DatabaseEvent doctorEvent = await _database.child("Doctor").once();
    Map<dynamic, dynamic>? doctorData =
        doctorEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (doctorData != null) {
      doctorData.forEach((key, value) {
        if (value["email"] == user.email) {
          setState(() {
            doctorId = key;
          });
        }
      });
    }

    if (doctorId == null) return;

    // Fetch Patients assigned to this doctor
    DatabaseEvent patientEvent = await _database.child("Patient").once();
    var patientSnapshot = patientEvent.snapshot.value;

    if (patientSnapshot == null || patientSnapshot is! List) {
      print("❌ No patients found in database.");
      return;
    }

    List<dynamic> patientListRaw = patientSnapshot;
    List<Map<String, dynamic>> patientList = [];

    for (var entry in patientListRaw) {
      if (entry == null || entry is! Map) continue;

      if (entry["Doctor_ID"].toString() == doctorId) {
        String treatmentPlanId = entry["Treatmentplan_ID"] ?? "";

        // Fetch Treatment Plan Data
        DatabaseEvent treatmentPlanEvent = await _database
            .child("TreatmentPlan")
            .child(treatmentPlanId)
            .once();
        var treatmentPlanSnapshot = treatmentPlanEvent.snapshot.value;

        Map<dynamic, dynamic>? treatmentPlanData =
            treatmentPlanSnapshot is Map ? treatmentPlanSnapshot : null;

        String actStatus = treatmentPlanData?["ACTst"] ?? "";
        String actScore = treatmentPlanData?["ACT"]?.toString() ?? "";
        bool isApproved = treatmentPlanData?["isApproved"] ?? false;

        patientList.add({
          "id": entry["Patient_ID"].toString(),
          "Fname": entry["Fname"] ?? "Unknown",
          "Lname": entry["Lname"] ?? "Unknown",
          "ACTst": actStatus,
          "ACT": actScore,
          "Is_Approve": isApproved,
        });
      }
    }

    setState(() {
      patients = patientList;
      _applySorting();
    });

    print("✅ Patients found for Doctor ID $doctorId: ${patients.length}");
  }

  // void _applySorting() {
  //   if (currentFilter == "Need Approve") {
  //     patients.sort((a, b) => a["Is_Approve"] == false ? -1 : 1);
  //   } else if (currentFilter == "Status") {
  //     patients.sort((a, b) => a["ACT"].compareTo(b["ACT"]));
  //   } else {
  //     patients.sort((a, b) {
  //       String nameA = "${a["Fname"]} ${a["Lname"]}".toLowerCase();
  //       String nameB = "${b["Fname"]} ${b["Lname"]}".toLowerCase();
  //       return nameA.compareTo(nameB);
  //     });
  //   }
  //   setState(() {});
  // }
  void _applySorting() {
    if (currentFilter == "Need Approve") {
      patients.sort((a, b) {
        bool aNeedsApproval = !a["Is_Approve"];
        bool bNeedsApproval = !b["Is_Approve"];

        bool aHasNoPlan = a["ACTst"].toString().isEmpty;
        bool bHasNoPlan = b["ACTst"].toString().isEmpty;

        // ✅ Move "No Treatment Plan Yet" to the bottom
        if (aHasNoPlan && !bHasNoPlan) return 1;
        if (!aHasNoPlan && bHasNoPlan) return -1;

        // ✅ Move "Approved" before "Need Approve"
        if (!aNeedsApproval && bNeedsApproval) return -1;
        if (aNeedsApproval && !bNeedsApproval) return 1;

        // ✅ Sorting by ACT Status (Red → Yellow → Green)
        List<String> priorityOrder = [
          "uncontrolled",
          "partly controlled",
          "controlled",
          ""
        ];

        int indexA = priorityOrder.indexOf(a["ACTst"].toString().toLowerCase());
        int indexB = priorityOrder.indexOf(b["ACTst"].toString().toLowerCase());

        return indexA.compareTo(indexB);
      });
    } else if (currentFilter == "Status") {
      // ✅ Sorting by ACT Status (Red → Yellow → Green → Empty)
      List<String> priorityOrder = [
        "uncontrolled",
        "partly controlled",
        "controlled",
        ""
      ];

      patients.sort((a, b) {
        int indexA = priorityOrder.indexOf(a["ACTst"].toString().toLowerCase());
        int indexB = priorityOrder.indexOf(b["ACTst"].toString().toLowerCase());

        return indexA.compareTo(indexB);
      });
    } else {
      // Default sorting (Alphabetical Order)
      patients.sort((a, b) {
        String nameA = "${a["Fname"]} ${a["Lname"]}".toLowerCase();
        String nameB = "${b["Fname"]} ${b["Lname"]}".toLowerCase();
        return nameA.compareTo(nameB);
      });
    }

    setState(() {});
  }

  Color _getStatusColor(String actStatus) {
    switch (actStatus.toLowerCase()) {
      case "controlled":
        return Colors.green;
      case "partly controlled":
        return Colors.yellow;
      case "uncontrolled":
        return Colors.red;
      default:
        return Colors.grey; // "No ACT yet"
    }
  }

  Color _getTreatmentPlanColor(bool isApproved) {
    return isApproved ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Text(
          "Patient List",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            // Sorting Bar (Styled)
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: const Color(0xFF6676AA).withOpacity(0.09),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton("All"),
                  _buildFilterButton("Need Approve"),
                  _buildFilterButton("Status"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Table Header
            Container(
              color: const Color(0xFF8699DA),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    flex: 2,
                    child: Text("Name", style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text("Status",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text("Treatment Plan",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),

            // Patient List
            Expanded(
              child: patients.isEmpty
                  ? const Center(child: Text("No patients found"))
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Name
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${patient["Fname"]} ${patient["Lname"]}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  // ACT Status + Score
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildStatusIndicator(
                                            _getStatusColor(patient["ACTst"])),
                                        const SizedBox(width: 5),
                                        Text(
                                          patient[
                                              "ACT"], // ACT Score or "No ACT yet"
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Treatment Plan
                                  //
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      patient["ACTst"].toString().isEmpty
                                          ? "No treatment plan yet"
                                          : (patient["Is_Approve"]
                                              ? "Approved"
                                              : "Need Approve"),
                                      style: TextStyle(
                                        color: patient["ACTst"]
                                                .toString()
                                                .isEmpty
                                            ? Colors
                                                .grey // Gray for no treatment plan
                                            : _getTreatmentPlanColor(
                                                patient["Is_Approve"]),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                debugPrint("🛠 Patient Data: $patient");

                                if (patient.containsKey("id") &&
                                    patient["id"] != null) {
                                  debugPrint(
                                      "✅ Navigating to Treatment Plan with ID: ${patient["id"]}");

                                  // ✅ Wait for the result when navigating back
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TreatmentPlanScreen(
                                        patientId: patient["id"].toString(),
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    debugPrint("🔄 Refreshing Patient List...");
                                    _fetchDoctorPatients(); // ✅ Refresh patient list
                                  }
                                } else {
                                  debugPrint(
                                      "❌ Error: Patient ID is null or missing.");
                                }
                              }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    return TextButton(
      onPressed: () {
        setState(() {
          currentFilter = text;
          _applySorting();
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: currentFilter == text
            ? const Color(0xFF8699DA)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: currentFilter == text ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Color color) {
    return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
