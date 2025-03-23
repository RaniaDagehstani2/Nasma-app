import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool isFormValid = false;

  // 🔹 Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  void _validateForm() {
    setState(() {
      isFormValid = _isValidEmail(emailController.text.trim());
    });
  }

  void _resetPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password reset link sent to your email.")),
      );
      Navigator.pop(context); // Go back to Sign In screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
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
      // 🔹 App Bar (Header) - Same as Sign-In Page
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Reset Password",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: "Nunito",
          ),
        ),
        automaticallyImplyLeading: true, // 🔙 Back Button (`<` icon)
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Enter your email to receive a password reset link.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),

            // 📧 Email Input (Styled like Sign-In)
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
            const SizedBox(height: 30),

            // 🔵 "Send Reset Link" Button (Styled like Sign-In)
            Center(
              child: ElevatedButton(
                onPressed: isFormValid && !isLoading ? _resetPassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid
                      ? const Color(0xFF8699DA) // 🔵 Enabled if valid
                      : const Color(0xFFB1B1B1), // 🔘 Disabled if invalid
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send Reset Link",
                        style: TextStyle(
                          fontSize: 19,
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
    );
  }
}
