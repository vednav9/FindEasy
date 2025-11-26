import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniproject6/models/category_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'routes.dart';
import 'widgets/location_picker_screen.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProviderRegisterScreenState createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _selectedServices = [];
  File? _selectedImage;
  GeoPoint? _geoPoint;
  String? _name;
  String? _email;

  Future<String> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance.ref().child(
      'provider_images/${_auth.currentUser!.uid}',
    );
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Location services are disabled.')),
  //     );
  //     return;
  //   }

  //   LocationPermission permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied ||
  //       permission == LocationPermission.deniedForever) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission != LocationPermission.always &&
  //         permission != LocationPermission.whileInUse) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Location permission denied.')),
  //       );
  //       return;
  //     }
  //   }

  //   Position position = await Geolocator.getCurrentPosition(
  //     locationSettings: const LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //       distanceFilter: 10,
  //     ),
  //   );
  //   setState(() {
  //     _geoPoint = GeoPoint(position.latitude, position.longitude);
  //   });
  // }

  void _registerProvider() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    String businessName = _businessNameController.text.trim();
    String contactNumber = _contactNumberController.text.trim();
    String address = _addressController.text.trim();
    String description = _descriptionController.text.trim();

    if (businessName.isEmpty ||
        contactNumber.isEmpty ||
        address.isEmpty ||
        _selectedServices.isEmpty ||
        description.isEmpty ||
        _selectedImage == null ||
        _geoPoint == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("All fields are required")));
      return;
    }

    try {
      final imageUrl = await _uploadImage(_selectedImage!);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userDoc = await _db.collection("users").doc(user.uid).get();
      _name = userDoc.data()?["name"] ?? "";
      _email = userDoc.data()?["email"] ?? "";

      await _db.collection("users").doc(user.uid).update({
        "businessName": businessName,
        "contactNumber": contactNumber,
        "address": address,
        "description": description,
        "servicesOffered": _selectedServices,
        "verificationStatus": "pending", // Default until verified
        "userType": "provider",
        "fcmToken": fcmToken,
      });

      // Create provider document
      await _db.collection("providers").doc(user.uid).set({
        "userId": user.uid,
        "name": _name,
        "email": _email,
        "businessName": businessName,
        "contactNumber": contactNumber,
        "address": address,
        "servicesOffered": _selectedServices,
        "verificationStatus": "pending",
        "rating": 0.0,
        "image": imageUrl,
        "description": description,
        "createdAt": FieldValue.serverTimestamp(),
        "fcmToken": fcmToken,
        "location": _geoPoint,
        "bookingCount": 0,
      });

      if (user.providerData.any((info) => info.providerId == 'password')) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification email sent. Please verify your email."),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created successfully! Please log in."),
          ),
        );
      }

      await _auth.signOut();
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Provider Registration"),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Business Name", _businessNameController),
            _buildTextField(
              "Contact Number",
              _contactNumberController,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField("Address", _addressController),
            _buildTextField(
              "Description",
              _descriptionController,
              keyboardType: TextInputType.multiline,
            ),

            SizedBox(height: 20),
            Text(
              "Services Offered",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children:
                  categoryList.map((category) {
                    return FilterChip(
                      label: Text(
                        category.title,
                        style: TextStyle(
                          color:
                              _selectedServices.contains(category.title)
                                  ? Colors.black
                                  : Colors.white,
                        ),
                      ),
                      selected: _selectedServices.contains(category.title),
                      selectedColor: Colors.orange,
                      backgroundColor: Colors.grey[800],
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(category.title);
                          } else {
                            _selectedServices.remove(category.title);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),

            SizedBox(height: 20),
            Text(
              "Location",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LocationPickerScreen(
                              onLocationPicked: (address, lat, lng) {
                                setState(() {
                                  _addressController.text = address;
                                  _geoPoint = GeoPoint(lat, lng);
                                });
                              },
                            ),
                      ),
                    );
                  },
                  icon: Icon(Icons.map, color: Colors.white),
                  label: Text("Pick Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_geoPoint != null)
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),

            SizedBox(height: 30),

            Text(
              "Upload Profile Image",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Tap to upload an image",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 10),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  image:
                      _selectedImage != null
                          ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    _selectedImage == null
                        ? Icon(Icons.upload, color: Colors.white, size: 40)
                        : null,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: _buildGradientButton(
                "Complete Registration",
                _registerProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: Colors.white),
            cursorColor: Colors.deepOrangeAccent,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
