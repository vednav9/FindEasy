import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_service.dart';
import '../../login_screen.dart';
import '../../main.dart';
import '../../widgets/dotted_border.dart';
import 'add_service_screen.dart';
import 'update_service_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  final String providerId;

  const ProviderHomeScreen({super.key, required this.providerId});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late User? _user;
  String displayName = "";
  List<String> servicesOffered = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadDisplayName();
    _fetchProviderServices();

    _firebaseService.requestPermission();
    _firebaseService.initFCMListeners();
    if (_user != null) {
      _firebaseService.saveTokenToFirestore(widget.providerId);
    }
  }

  Future<void> _loadDisplayName() async {
    if (_user != null) {
      final doc = await _db.collection("users").doc(widget.providerId).get();
      setState(() {
        displayName = doc.data()?["name"] ?? _user!.displayName ?? "User";
      });
    }
  }

  Future<void> _fetchProviderServices() async {
    final doc = await _db.collection("providers").doc(widget.providerId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        servicesOffered = List<String>.from(data["servicesOffered"] ?? []);
        isLoading = false;
      });
    }
  }

  Future<void> _removeService(String category) async {
    await _db.collection("providers").doc(widget.providerId).update({
      'servicesOffered': FieldValue.arrayRemove([category]),
    });
    await FirebaseFirestore.instance
        .collection("providers")
        .doc(widget.providerId)
        .collection("services")
        .doc(category)
        .delete();
    // the below code removes images from storage
    final serviceDoc =
        await FirebaseFirestore.instance
            .collection("providers")
            .doc(widget.providerId)
            .collection("services")
            .doc(category)
            .get();
    if (serviceDoc.exists) {
      final data = serviceDoc.data() as Map<String, dynamic>;
      final images = List<String>.from(data["images"] ?? []);
      for (String imageUrl in images) {
        deleteImageFromStorage(imageUrl);
      }
    }
    setState(() {
      servicesOffered.remove(category);
    });
  }

  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print("Error deleting image from storage: $e");
    }
  }

  Future<void> _confirmDeleteService(BuildContext context, String category) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete $category?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _removeService(category);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => _signOut(context),
              child: Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildAddServiceCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddServiceScreen(providerId: widget.providerId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DottedBorderCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Add a Service",
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.09,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => BottomNavBarWrapper(
                            userType: "provider",
                            initialIndex: 3,
                          ),
                    ),
                  ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage:
                      _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : AssetImage('assets/login_background.png')
                              as ImageProvider,
                  radius: 23,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Hello, $displayName",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lato',
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Your Services",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  SizedBox(height: 10),
                  ...servicesOffered.map(
                    (service) => Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 10,
                        ),
                        title: Text(
                          service,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lato',
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => _confirmDeleteService(context, service),
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UpdateServiceScreen(
                                      providerId: widget.providerId,
                                      category: service,
                                    ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildAddServiceCard(),
                ],
              ),
    );
  }
}
