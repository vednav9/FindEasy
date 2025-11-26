import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class AddServiceScreen extends StatefulWidget {
  final String providerId;

  const AddServiceScreen({super.key, required this.providerId});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  List<String> _servicesOffered = [];

  @override
  void initState() {
    super.initState();
    _fetchServicesOffered();
  }

  Future<void> _fetchServicesOffered() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(widget.providerId)
            .get();
    setState(() {
      _servicesOffered = List<String>.from(
        doc.data()?['servicesOffered'] ?? [],
      );
    });
  }

  Future<void> _confirmAndAddService(
    BuildContext context,
    String categoryTitle,
  ) async {
    final alreadyExists = _servicesOffered.contains(categoryTitle);
    if (alreadyExists) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Add Service"),
            content: Text(
              "Are you sure you want to add \"$categoryTitle\" service?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes, Add"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final docRef = FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.providerId);

    await docRef.collection('services').doc(categoryTitle).set({
      'description': '',
      'address': '',
      'contactNumber': '',
      'images': [],
    });

    await docRef.update({
      'servicesOffered': FieldValue.arrayUnion([categoryTitle]),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$categoryTitle added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a Service"),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categoryList.length,
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final isAdded = _servicesOffered.contains(category.title);

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            color: isAdded ? Colors.grey[300] : Colors.white,
            child: ListTile(
              enabled: !isAdded,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              leading: Icon(
                category.icon,
                color: isAdded ? Colors.grey : Colors.orange,
              ),
              title: Text(
                category.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAdded ? Colors.grey : Colors.black,
                ),
              ),
              trailing:
                  isAdded ? const Icon(Icons.check, color: Colors.grey) : null,
              onTap: () => _confirmAndAddService(context, category.title),
            ),
          );
        },
      ),
    );
  }
}
