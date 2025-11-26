import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../login_screen.dart';
import '../../routes.dart';
import '../../widgets/location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  // late User? _user;

  Future<DocumentSnapshot> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
  }

  @override
  void initState() {
    super.initState();
    // _user = _auth.currentUser;
    // _visibilityOfResetPasswordButton;
  }

  // Future<void> _visibilityOfResetPasswordButton() async {
  //   if (_user != null) {
  //     final methods =  _user!.providerData.map((info) => info.providerId).toList();
  //     if (methods.contains('password')) {
  //       setState(() {
  //         _visibilityOfResetPasswordButton = true;
  //       });
  //     } else {
  //       setState(() {
  //         _visibilityOfResetPasswordButton = false;
  //       });
  //     }
  //   }
  // }

  Future<void> _updateLocation(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationPickerScreen(
              onLocationPicked: (address, lat, lng) async {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                      'address': address,
                      'location': GeoPoint(lat, lng),
                    });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Location updated successfully"),
                  ),
                );
              },
            ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => _signOut(context),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileContent(data, user!);
        },
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> data, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : const AssetImage('assets/login_background.png')
                        as ImageProvider,
          ),
          const SizedBox(height: 10),
          Text(
            data['name'] ?? 'No Name',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data['email'] ?? 'No Email',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          _buildInfoTile("User Type", data['userType'] ?? 'N/A'),
          _buildInfoTile("Contact", data['contactNumber'] ?? 'Not provided'),
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _buildInfoTile("Address", "Not provided");
              }

              final updatedData = snapshot.data!.data() as Map<String, dynamic>;
              return _buildInfoTile(
                "Address",
                updatedData.containsKey('address') &&
                        updatedData['address'] != null
                    ? updatedData['address']
                    : 'Not provided',
              );
            },
          ),

          const SizedBox(height: 30),
          _buildActionButton(
            icon: Icons.edit,
            label: "Edit Profile",
            color: Colors.blue,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.location_on,
            label: "Update Location",
            color: Colors.deepPurple,
            onPressed: () {
              _updateLocation(context);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.history,
            label: "My Bookings",
            color: Colors.green,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.booking);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout,
            label: "Logout",
            color: Colors.red,
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        Row(
          children: [
            Text(
              "$title: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
