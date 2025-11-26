import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdateServiceScreen extends StatefulWidget {
  final String providerId;
  final String category;

  const UpdateServiceScreen({
    super.key,
    required this.providerId,
    required this.category,
  });

  @override
  State<UpdateServiceScreen> createState() => _UpdateServiceScreenState();
}

class _UpdateServiceScreenState extends State<UpdateServiceScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _businessNameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  List<String> _imageUrls = [];
  List<XFile> _newImages = [];

  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadServiceData();
  }

  Future<void> _loadServiceData() async {
    final doc =
        await _db
            .collection('providers')
            .doc(widget.providerId)
            .collection('services')
            .doc(widget.category)
            .get();

    if (doc.exists) {
      final data = doc.data();
      _businessNameController.text = data?['businessName'] ?? '';
      _descController.text = data?['description'] ?? '';
      _addressController.text = data?['address'] ?? '';
      _contactController.text = data?['contactNumber'] ?? '';
      _imageUrls = List<String>.from(data?['images'] ?? []);
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _newImages = pickedFiles;
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> downloadUrls = [];
    for (var image in _newImages) {
      final ref = FirebaseStorage.instance.ref().child(
        'provider_images/${widget.providerId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = await ref.putFile(File(image.path));
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> _saveServiceData() async {
    final newUrls = await _uploadImages();
    _imageUrls.addAll(newUrls);

    await _db
        .collection('providers')
        .doc(widget.providerId)
        .collection('services')
        .doc(widget.category)
        .set({
          'businessName': _businessNameController.text.trim(),
          'description': _descController.text.trim(),
          'address': _addressController.text.trim(),
          'contactNumber': _contactController.text.trim(),
          'images': _imageUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Service details updated.")));

    Navigator.pop(context);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _imageUrls
              .map(
                (url) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit ${widget.category}"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Service Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTextField(
                              "Business Name",
                              _businessNameController,
                            ),
                            _buildTextField(
                              "Description",
                              _descController,
                              maxLines: 3,
                            ),
                            _buildTextField("Address", _addressController),
                            _buildTextField(
                              "Contact Number",
                              _contactController,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      "Uploaded Images",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _imageUrls.isEmpty
                        ? const Text("No images yet.", 
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ))
                        : _buildImagePreview(),

                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text("Add More Photos"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
                          side: const BorderSide(color: Colors.deepOrange),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Save", style: TextStyle(fontSize: 16)),
                      onPressed: _saveServiceData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
