import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isCustomerSelected = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  bool _isProviderRegistrationComplete(DocumentSnapshot doc) {
    final userType = doc.get("userType") ?? "customer";

    // Only check provider fields if user is actually a provider
    if (userType == "provider") {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('businessName')) {
        return data['businessName'] != null &&
               data['contactNumber'] != null &&
               data['servicesOffered'] != null;
      }
    }

    // Customers are always considered "complete"
    return true;
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled sign-in

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();

      final userDoc = _db.collection("users").doc(user.uid);
      final doc = await userDoc.get();

      if (doc.exists) {
        // **User already exists → Redirect to home**
        await userDoc.update({"fcmToken": token});
        final userType = doc.get("userType") ?? "customer";
        final isComplete = _isProviderRegistrationComplete(doc);

        if (userType == "provider") {
          Navigator.pushReplacementNamed(
            context,
            isComplete ? AppRoutes.providerHome : AppRoutes.providerRegister,
          );
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
      } else {
        // **New User → Register in Firestore**
        await userDoc.set({
          "name": user.displayName ?? "User",
          "email": user.email,
          "userType": isCustomerSelected ? "customer" : "provider",
          "createdAt": Timestamp.now(),
          "fcmToken": token,
        });

        if (isCustomerSelected) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.providerRegister);
        }
      }
    } catch (e) {
      _showError("Google Sign-In Failed: ${e.toString()}");
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool isPasswordValid(String password) {
    final RegExp regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&+=]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  void _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError("All fields are required");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    if (!isPasswordValid(password)) {
      _showDialog(
        "Password must be 8+ chars, include uppercase, number, and special char.",
      );
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final token = await FirebaseMessaging.instance.getToken();

      await _db.collection("users").doc(userCredential.user!.uid).set({
        "name": name,
        "email": email,
        "userType": isCustomerSelected ? "customer" : "provider",
        "createdAt": Timestamp.now(),
        "fcmToken": token,
      });

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackbar("Verification email sent. Please verify your email.");
      }

      final userDoc = await _db.collection("users").doc(user.uid).get();
      final isComplete = _isProviderRegistrationComplete(userDoc);

      if (isCustomerSelected) {
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      } else {
        Navigator.pushReplacementNamed(
          context,
          isComplete ? AppRoutes.providerHome : AppRoutes.providerRegister,
        );
      }
      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      _showError("Registration Failed: ${e.toString()}");
    }
  }

  void _showSnackbar(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Password Requirements"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
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
              // Background Image
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/login_background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Heading Text
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 10),

              // Name Input
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    label: Text("Full Name"),
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.person, color: Colors.white),
                    filled: true,
                    fillColor: Color(0xFF333333),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 15),

              // Email Input
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    label: Text("Email"),
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                    filled: true,
                    fillColor: Color(0xFF333333),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 15),

              // Password Input with Toggle Visibility
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    label: Text("Password"),
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    filled: true,
                    fillColor: Color(0xFF333333),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 15),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    label: Text("Confirm Password"),
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                    filled: true,
                    fillColor: Color(0xFF333333),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white, width: 2.5),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 15),

              // User Type Selector
              Container(
                height: screenHeight * 0.055,
                width: MediaQuery.of(context).size.width - 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment:
                          isCustomerSelected
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                      duration: Duration(milliseconds: 200),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 120) / 2,
                        margin:
                            isCustomerSelected
                                ? EdgeInsets.only(left: 3)
                                : EdgeInsets.only(right: 3),
                        height: screenHeight * 0.047,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 246, 49, 45),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              blurRadius: 5,
                              spreadRadius: 0.6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () => setState(() => isCustomerSelected = true),
                            child: Center(
                              child: Text(
                                "Customer",
                                style: TextStyle(
                                  color:
                                      isCustomerSelected
                                          ? Colors.white
                                          : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () =>
                                    setState(() => isCustomerSelected = false),
                            child: Center(
                              child: Text(
                                "Provider",
                                style: TextStyle(
                                  color:
                                      isCustomerSelected
                                          ? Colors.black
                                          : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 15),

              // Register Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                height: screenHeight * 0.055,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 246, 49, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(
                    "Register",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 5),

              // OR Text
              Text("Or Register With", style: TextStyle(color: Colors.white)),

              SizedBox(height: 15),

              // Google Sign-In Button (Using Google Logo and White Background)
              GestureDetector(
                onTap: _signInWithGoogle,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: 0.3,
                        ), // 👈 Light white shadow
                        spreadRadius: 3.5,
                        blurRadius: 5, // 👈 Slight downward shadow
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset("assets/ic_google.png", height: 30),
                  ),
                ),
              ),

              // Login Redirect
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
                child: Text(
                  "Already have an account? Login",
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
