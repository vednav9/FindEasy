import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return FutureBuilder<String>(
            future: _getUserType(snapshot.data!.uid),
            builder: (context, AsyncSnapshot<String> userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userTypeSnapshot.hasData) {
                Future.microtask(() {
                  Navigator.pushReplacementNamed(
                    context,
                    userTypeSnapshot.data == "provider"
                        ? AppRoutes.providerHome
                        : AppRoutes.customerHome,
                  );
                });
                return const Center(child: CircularProgressIndicator());
              }

              Future.microtask(() {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              });
              return const Center(child: CircularProgressIndicator());
            },
          );
        }

        Future.microtask(() {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        });

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<String> _getUserType(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return userDoc.exists ? userDoc.get("userType") : "customer"; 
  }
}
