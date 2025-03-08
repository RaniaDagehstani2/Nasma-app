import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'sign_up_next_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isIdValid = false;
  bool isFirstNameValid = false;
  bool isLastNameValid = false;
  bool isPhoneValid = false;

  bool emailSent = false; // Track if verification email is sent

  void _validateFields() {
    setState(() {
      isEmailValid = emailController.text.trim().isNotEmpty;
      isPasswordValid = passwordController.text.trim().isNotEmpty;
      isIdValid = RegExp(r'^\d+$').hasMatch(idController.text.trim());
      isFirstNameValid =
          RegExp(r'^[a-zA-Z]+$').hasMatch(firstNameController.text.trim());
      isLastNameValid =
          RegExp(r'^[a-zA-Z]+$').hasMatch(lastNameController.text.trim());
      isPhoneValid = RegExp(r'^05\d{8}$').hasMatch(phoneController.text.trim());
    });
  }

  bool get isFormValid =>
      isEmailValid &&
      isPasswordValid &&
      isIdValid &&
      isFirstNameValid &&
      isLastNameValid &&
      isPhoneValid;

  void _signUp() async {
    if (!isFormValid) return; // Prevent signing up if form is invalid

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      await user?.sendEmailVerification(); // Send verification email

      setState(() {
        emailSent = true; // Update UI to show "Verification Sent" message
      });

      String userId = idController.text.trim();

      await _database.child("users").child(userId).set({
        "email": emailController.text.trim(),
        "id": userId,
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "phone": int.tryParse(phoneController.text.trim()) ?? 0,
        "emailVerified": false, // Track verification status
      });

      // Show a dialog asking the user to verify email
      _showVerificationDialog(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _showVerificationDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false, // User can't dismiss the dialog
      builder: (context) => AlertDialog(
        title: const Text("Verify Your Email"),
        content: const Text(
            "A verification email has been sent to your email address. Please check your inbox and verify your account."),
        actions: [
          TextButton(
            onPressed: () async {
              await _auth.currentUser?.reload(); // Reload user info
              if (_auth.currentUser?.emailVerified ?? false) {
                // Update database to mark email as verified
                await _database.child("users").child(userId).update({
                  "emailVerified": true,
                });

                // Navigate to next screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpNextScreen(
                      userId: userId,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email not verified yet!")),
                );
              }
            },
            child: const Text("I've Verified My Email"),
          ),
          TextButton(
            onPressed: () {
              _auth.currentUser?.sendEmailVerification(); // Resend email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Verification email sent again!")),
              );
            },
            child: const Text("Resend Email"),
          ),
        ],
      ),
    );
  }

  // Returns the appropriate error text based on the label and its validation state.
  String? getErrorText(String label) {
    switch (label) {
      case "Email":
        return isEmailValid ? null : "Email cannot be empty";
      case "Password":
        return isPasswordValid ? null : "Password cannot be empty";
      case "ID":
        return isIdValid ? null : "ID must be numbers only";
      case "First Name":
        return isFirstNameValid ? null : "First name must contain only letters";
      case "Last Name":
        return isLastNameValid ? null : "Last name must contain only letters";
      case "Phone Number":
        return isPhoneValid
            ? null
            : "Phone must be 10 digits & start with '05'";
      default:
        return null;
    }
  }

  // Builds a custom text field with the applied UI constraints and error message.
  Widget _buildLabeledTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            onChanged: (_) => _validateFields(),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: "Nunito",
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Color(0xFF8699DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Color(0xFF8699DA), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Color(0xFF8699DA), width: 2),
              ),
            ),
          ),
          if (getErrorText(label) != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                getErrorText(label)!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Nunito",
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: "Nunito",
                        ),
                      ),
                      TextSpan(
                        text: "Log in",
                        style: const TextStyle(
                          color: Color(0xFF8699DA),
                          fontSize: 14,
                          fontFamily: "Nunito",
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignInScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(emailController, "Email"),
                _buildLabeledTextField(passwordController, "Password",
                    isPassword: true),
                _buildLabeledTextField(idController, "ID", isNumeric: true),
                _buildLabeledTextField(firstNameController, "First Name"),
                _buildLabeledTextField(lastNameController, "Last Name"),
                _buildLabeledTextField(phoneController, "Phone Number",
                    isNumeric: true),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: isFormValid ? _signUp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFormValid
                          ? const Color(0xFF8699DA)
                          : const Color(0xFFB1B1B1),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Sign Up",
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
      ),
    );
  }
}
