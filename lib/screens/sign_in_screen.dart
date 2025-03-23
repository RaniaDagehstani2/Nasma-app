import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
//import 'homepage.dart'; // User's home page
import 'homepage.dart';
import 'package:testtest/screens/homepage.dart';
import 'package:testtest/screens/password_reset_screen.dart';
import 'patient_list_screen.dart'; // Doctor's patient list page
import 'sign_up_screen.dart'; // Navigation to Sign Up

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isFormValid = false;

  void _validateForm() {
    setState(() {
      isFormValid = emailController.text.trim().isNotEmpty &&
          passwordController.text.trim().isNotEmpty;
    });
  }

  void _signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        String userEmail = emailController.text.trim().toLowerCase();
        String firebaseUserId = user.uid; // ✅ Firebase Auth UID
        String? userId;

        print("🔥 Firebase Auth UID: $firebaseUserId");
        DatabaseReference usersRef = _database.child("users");
        DatabaseEvent event =
            await usersRef.orderByChild("email").equalTo(user.email).once();

        // Check if email exists in "Doctors"
        DatabaseEvent doctorEvent = await _database
            .child("Doctor")
            .orderByChild("email")
            .equalTo(userEmail)
            .once();
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> usersMap =
              Map<dynamic, dynamic>.from(event.snapshot.value as Map);

          // ✅ Extract the correct database ID
          usersMap.forEach((key, value) {
            if (value["email"] == user.email) {
              userId = value["id"]; // ✅ Get the correct "id"
            }
          });

          print("✅ Matched Database User ID: $userId");
        }
        if (doctorEvent.snapshot.value != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientListScreen()),
          );
          return;
        }

        // Check if email exists in "Users"
        DatabaseEvent userEvent = await _database
            .child("users")
            .orderByChild("email")
            .equalTo(userEmail)
            .once();

        if (userEvent.snapshot.value != null) {
          print("Navigating to HomeScreen");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(userId: userId!)),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No account found for this email.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email or password wrong")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: const [
                    Text(
                      "WELCOME BACK!",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Nunito",
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Color(0xFF8699DA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Email Field
              TextField(
                controller: emailController,
                onChanged: (_) => _validateForm(),
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF8699DA)),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: passwordController,
                onChanged: (_) => _validateForm(),
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF8699DA)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PasswordResetScreen(), // Navigate to Reset Screen
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFF8699DA), // Same color as Sign Up link
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Add spacing before Sign In button

              // Sign In Button
              Center(
                child: ElevatedButton(
                  onPressed: isFormValid && !isLoading ? _signIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid
                        ? const Color(0xFF8699DA)
                        : const Color(0xFFB1B1B1),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 80),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 5,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
