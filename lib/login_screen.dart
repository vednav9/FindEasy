import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isCustomerSelected = true;
  bool _isPasswordVisible = false;

  bool _isProviderRegistrationComplete(DocumentSnapshot doc) {
    final userType = doc.get("userType") ?? "customer";

    // Only check provider fields if user is actually a provider
    if (userType == "provider") {
      return doc.get("businessName") != null &&
          doc.get("contactNumber") != null &&
          doc.get("servicesOffered") != null;
    }

    // Customers are always considered "complete"
    return true;
  }

  Future<void> _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Ensure the user is signed out before attempting a new sign-in
    await googleSignIn.signOut();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc =
            await _db.collection("users").doc(user.uid).get();

        if (!doc.exists) {
          await _db.collection("users").doc(user.uid).set({
            "name": user.displayName,
            "email": user.email,
            "userType": isCustomerSelected ? "customer" : "provider",
            "createdAt": Timestamp.now(),
          });
        }

        final firebaseService = FirebaseService();
        await firebaseService.saveTokenToFirestore(
          user.uid,
        ); // ✅ Save FCM token

        if (!doc.exists) {
          Navigator.pushReplacementNamed(
            context,
            isCustomerSelected
                ? AppRoutes.customerHome
                : AppRoutes.providerRegister,
          );
        } else {
          String userType = doc.get("userType") ?? "customer";
          bool isComplete = _isProviderRegistrationComplete(doc);

          if (userType == "provider") {
            Navigator.pushReplacementNamed(
              context,
              isComplete ? AppRoutes.providerHome : AppRoutes.providerRegister,
            );
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: ${e.toString()}")),
      );
    }
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Either email or password is empty")),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (!user!.emailVerified) {
        await _auth.signOut();
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text("Email Not Verified"),
                content: Text(
                  "Your email address is not verified. Would you like us to resend the verification email?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await user.sendEmailVerification();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Verification email sent."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to resend verification email.",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text("Resend"),
                  ),
                ],
              ),
        );
        return;
      }

      DocumentSnapshot userDoc =
          await _db.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        final firebaseService = FirebaseService();
        await firebaseService.saveTokenToFirestore(
          user.uid,
        ); // ✅ Save FCM token

        String userType = userDoc.get("userType") ?? "customer";
        bool isComplete = _isProviderRegistrationComplete(userDoc);

        if (userType == "provider") {
          Navigator.pushReplacementNamed(
            context,
            isComplete ? AppRoutes.providerHome : AppRoutes.providerRegister,
          );
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensures UI fits on one screen
            children: [
              // Background Image (Fixed Width & Height)
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

              SizedBox(height: 10),

              // Welcome Text
              Text(
                "Welcome to FindEasy",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 10),

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
                    hintStyle: TextStyle(color: Colors.white),
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
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2.5,
                      ), // 👈 Focused border color
                    ),
                    floatingLabelBehavior:
                        FloatingLabelBehavior
                            .auto, // 👈 Default Material Effect
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              SizedBox(height: 15),

              // Password Input
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: screenHeight * 0.07,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    label: Text("Password"),
                    labelStyle: TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible =
                              !_isPasswordVisible; // Toggle password visibility
                        });
                      },
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
                      borderSide: BorderSide(
                        color: Colors.white,
                        width: 2.5,
                      ), // 👈 Focused border color
                    ),
                    floatingLabelBehavior:
                        FloatingLabelBehavior
                            .auto, // 👈 Default Material Effect
                  ),
                  style: TextStyle(color: Colors.white),
                  autofocus: false,
                ),
              ),

              // Forgot Password
              SizedBox(
                width: MediaQuery.of(context).size.width - 70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text(
                      "Forgot Password ?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 5),

              // User Type Toggle (Fixed Alignment)
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
                          color: const Color.fromARGB(255, 246, 49, 45),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(),
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

              // Login Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                height: screenHeight * 0.055,
                child: ElevatedButton(
                  onPressed: _login,
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
                  child: Text("Login", style: TextStyle(color: Colors.white)),
                ),
              ),

              SizedBox(height: 5),

              // OR Text
              Text("Or Login With", style: TextStyle(color: Colors.white)),

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

              SizedBox(height: 5),

              // Register Text
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: Text(
                  "Don't have an account? Register",
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
