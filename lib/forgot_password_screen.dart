import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || _secondsRemaining > 0) {
      return; // Prevent spamming
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      // Start cooldown (60 seconds)
      setState(() {
        _secondsRemaining = 60;
      });
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reset link sent! Check your email.")),
      );
    } catch (error) {
      setState(() {
        _errorMessage = "Error: ${error.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel(); // Cancel any existing timer
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/login_background.png"),
                    fit: BoxFit.cover, // Ensures it fills the width properly
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.white,
                          width: 2.5,
                        ), // 👈 Focused border color
                      ),
                      filled: true,
                      fillColor: Color(0xFF333333),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your email";
                      }
                      if (!RegExp(
                        r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
                      ).hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              
              const SizedBox(height: 20),

              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: screenHeight * 0.055,
                    child: ElevatedButton(
                      onPressed: _secondsRemaining > 0 ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 246, 49, 45),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        _secondsRemaining > 0
                            ? "Try Again in $_secondsRemaining sec"
                            : "Send Link",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
                child: Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
