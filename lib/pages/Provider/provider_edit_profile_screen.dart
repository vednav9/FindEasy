import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() => _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  String? _photoURL;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection('providers').doc(user.uid).get();
    final data = doc.data();

    _nameController.text = data?['name'] ?? '';
    _contactController.text = data?['contactNumber'] ?? '';
    _addressController.text = data?['address'] ?? '';
    _emailController.text = data?['email'] ?? '';
    _photoURL = user.photoURL;

    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'contactNumber': _contactController.text.trim(),
        'address': _addressController.text.trim(),
      });

      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _changeImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final user = _auth.currentUser;
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');
      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(downloadUrl);
      await _db.collection('users').doc(user.uid).update({
        'photoURL': downloadUrl,
      });
      setState(() => _photoURL = downloadUrl);
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset link sent to your email")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send reset email: ${e.toString()}")),
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        cursorColor: Colors.black,
        keyboardType: label == "Contact Number"
            ? TextInputType.phone
            : label == "Email"
                ? TextInputType.emailAddress
                : TextInputType.text,
        enabled: enabled,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        onSubmitted: (value) => FocusScope.of(context).unfocus(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.orange,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _changeImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _photoURL != null
                                ? NetworkImage(_photoURL!)
                                : const AssetImage(
                                      'assets/login_background.png',
                                    )
                                    as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Full Name", _nameController),
                    _buildTextField("Contact Number", _contactController),
                    _buildTextField("Address", _addressController),
                    _buildTextField("Email", _emailController),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white, size: 24,),
                      label: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 18),),
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (FirebaseAuth
                            .instance
                            .currentUser
                            ?.providerData
                            .first
                            .providerId ==
                        'password')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue
                      ),
                      onPressed: _sendPasswordReset,
                       child: Text(
                        "Reset Password",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
