import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';
import 'routes.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Setup FCM centrally
  final firebaseService = FirebaseService();
  await firebaseService.requestPermission();
  firebaseService.initFCMListeners();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await firebaseService.saveTokenToFirestore(user.uid);
  }

  // ✅ Setup local notifications
  await firebaseService.setupFlutterNotifications();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(GlobalWrapper(child: MyApp()));
}

// ✅ Apply SafeArea & System UI styling globally
class GlobalWrapper extends StatelessWidget {
  final Widget child;
  const GlobalWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.orange,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.orange,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: SafeArea(child: child),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FindEasy',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      initialRoute: AppRoutes.authCheck,
      routes: AppRoutes.routes,
    );
  }
}

// ✅ Authentication Check to Redirect Users Dynamically
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
                // ✅ FIX: Use Future.microtask() to navigate & return a placeholder widget
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

              // ✅ FIX: Use Future.microtask() before returning widget
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

  // Fetch user type (customer/provider) from Firestore
  Future<String> _getUserType(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return userDoc.exists ? userDoc.get("userType") : "customer";
  }
}

// ✅ Wrapper for Bottom Navigation Bar
class BottomNavBarWrapper extends StatefulWidget {
  final String userType;
  final int initialIndex;

  const BottomNavBarWrapper({
    super.key,
    required this.userType,
    required this.initialIndex,
  });

  @override
  // ignore: library_private_types_in_public_api
  _BottomNavBarWrapperState createState() => _BottomNavBarWrapperState();
}

class _BottomNavBarWrapperState extends State<BottomNavBarWrapper> {
  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      userType: widget.userType,
      initialIndex: widget.initialIndex,
      userId: FirebaseAuth.instance.currentUser?.uid ?? "", // Pass userId
    );
  }
}
