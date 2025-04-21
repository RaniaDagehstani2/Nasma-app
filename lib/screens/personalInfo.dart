import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'footer.dart';
import 'personalInfo.dart';
import 'homepage.dart';
import 'connect_patch_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String userId; // 👈 Add this
  final String patientId;
  final String previousPage;

  PersonalInfoScreen({
    required this.userId, // 👈 Add this
    required this.patientId,
    required this.previousPage,
  });

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  late String patientId; // Store the patientId footer
  int _selectedIndex = 2; // Profile tab is selected footer
  String patientEmail = "Loading...";

  final Map<String, TextEditingController> controllers = {
    "Fname": TextEditingController(),
    "Lname": TextEditingController(),
    "EM_phone": TextEditingController(),
    "Gender": TextEditingController(),
    "Weight": TextEditingController(),
    "Height": TextEditingController(),
    "Date_of_birth": TextEditingController(),
    "Is_pregnant": TextEditingController(),
    "Has_allergy": TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId; // Get patientId from HomeScreen
    fetchUserData();
  }

  // ✅ Function to handle back navigation
  void _handleBackNavigation() {
    if (widget.previousPage == "home") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(userId: widget.userId)),
      );
    } else if (widget.previousPage == "dashboard") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ConnectPatchScreen(userId: widget.userId)),
      );
    } else {
      Navigator.pop(
          context); // Default behavior if the previous page is unknown
    }
  }
  //-----------------------------------------------

  Future<void> fetchUserData() async {
    try {
      // ✅ Fetch patient details first
      DatabaseEvent patientEvent =
          await _database.child("Patient").child(patientId).once();

      if (patientEvent.snapshot.exists) {
        Map<dynamic, dynamic>? patientData =
            patientEvent.snapshot.value as Map<dynamic, dynamic>?;

        if (patientData != null) {
          setState(() {
            controllers.forEach((key, controller) {
              controller.text = patientData[key]?.toString() ?? "";
            });
          });

          // ✅ Fetch the full "users" list
          DatabaseEvent userEvent = await _database.child("users").once();

          if (userEvent.snapshot.exists) {
            Map<dynamic, dynamic> usersData =
                userEvent.snapshot.value as Map<dynamic, dynamic>;

            // ✅ Loop through the list and find matching email
            usersData.forEach((key, user) {
              if (user["id"].toString() == widget.userId) {
                setState(() {
                  patientEmail = user["email"] ?? "No Email Found";
                });

                print("✅ User Email Found: $patientEmail");
              }
            });
          } else {
            print("❌ No users data found in Firebase.");
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
    }
  }

  //------------------------------------Front-end----------------------------------
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color.fromARGB(255, 102, 118, 170), // Highlight color
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 102, 118, 170),
            ),
            dialogBackgroundColor:
                Colors.white, // Calendar inside background white
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controllers["Date_of_birth"]!.text =
            "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  Future<void> saveChanges() async {
    try {
      Map<String, dynamic> updatedData = {};

      controllers.forEach((key, controller) {
        updatedData[key] = controller.text;
      });

      await _database.child("Patient").child(patientId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Changes saved successfully!")),
      );

      // Navigate back to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(userId: widget.userId)),
      );
    } catch (e) {
      print("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save changes. Try again!")),
      );
    }
  }

  String getProfileImage() {
    if (controllers["Gender"]!.text.toLowerCase() == "male") {
      return 'assets/man.png';
    } else if (controllers["Gender"]!.text.toLowerCase() == "female") {
      return 'assets/woman.png';
    }
    return 'assets/user.png';
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _handleBackNavigation, // ✅ Use dynamic navigation
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Color.fromARGB(255, 254, 255, 255), // Profile circle color
              ),
              padding: EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(getProfileImage()),
              ),
            ),

            SizedBox(height: 10),
            Text(
              "${controllers["Fname"]!.text.isEmpty ? "First" : controllers["Fname"]!.text} "
              "${controllers["Lname"]!.text.isEmpty ? "Last" : controllers["Lname"]!.text}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Patient ID (Non-editable)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextFormField(
                initialValue: patientId,
                decoration: InputDecoration(
                  labelText: "Patient ID",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                readOnly: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextFormField(
                key: Key(
                    patientEmail), // Ensures UI updates when email is loaded
                initialValue: patientEmail,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                readOnly: true, // Prevent user from editing email
              ),
            ),

            // Other Fields
            ...controllers.entries.map((entry) {
              bool isDateField = entry.key == "Date_of_birth";

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key.replaceAll('_', ' '),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: isDateField
                        ? IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          )
                        : null,
                  ),
                  readOnly: isDateField,
                  onTap: isDateField ? () => _selectDate(context) : null,
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveChanges, // Call saveChanges() when clicked
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8699DA),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
