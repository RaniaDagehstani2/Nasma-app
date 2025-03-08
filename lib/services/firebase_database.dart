import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _treatmentPlansRef = FirebaseDatabase.instance
      .ref()
      .child('TreatmentPlan'); // ✅ Corrected path

  // Add Treatment Plan to Firebase
  Future<void> addTreatmentPlan({
    required String treatmentPlanId,
    required int actScore,
    required String dosage,
    required List<String> intakeTimes,
    required bool isApproved,
    required String medicationName,
    required String stepNum,
  }) async {
    await _treatmentPlansRef.child(treatmentPlanId).set({
      'ACT': actScore,
      'dosage': dosage,
      'intakeTimes': {'timeId1': intakeTimes[0], 'timeId2': intakeTimes[1]},
      'isApproved': isApproved,
      'name': medicationName,
      'stepNum': stepNum,
    });
  }

  // Fetch Treatment Plan Data by ID
  Future<Map<String, dynamic>> getTreatmentPlan(String treatmentPlanId) async {
    DataSnapshot treatmentPlanSnapshot =
        await _treatmentPlansRef.child(treatmentPlanId).get();
    if (treatmentPlanSnapshot.exists) {
      Map<String, dynamic> treatmentPlanData =
          Map<String, dynamic>.from(treatmentPlanSnapshot.value as Map);
      return treatmentPlanData;
    } else {
      throw Exception("Treatment plan not found");
    }
  }
}
