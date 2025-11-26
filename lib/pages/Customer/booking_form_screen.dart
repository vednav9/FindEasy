import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../firebase_service.dart';
import '../../widgets/location_picker_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String serviceName;

  const BookingFormScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.serviceName,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  String _customerName = '';
  String _providerName = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomerName();
    _fetchProviderName();
    _fetchSavedAddress();
  }

  Future<void> _fetchCustomerName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _customerName = doc.data()?['name'] ?? '';
    });
  }

  Future<void> _fetchProviderName() async {
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(widget.providerId)
        .get();
    setState(() {
      _providerName = doc.data()?['name'] ?? '';
    });
  }

  Future<void> _fetchSavedAddress() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final savedAddress = doc.data()?['address'] ?? '';
    setState(() {
      _addressController.text = savedAddress;
    });
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final bookingData = {
      'customerId': uid,
      'providerId': widget.providerId,
      'providerName': _providerName,
      'customerName': _customerName,
      'serviceName': widget.serviceName,
      'date': _selectedDate!.toIso8601String().split('T')[0],
      'time': _selectedTime!.format(context),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
      'status': 'pending',
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('bookings').add(bookingData);

    await _sendBookingNotification(
      providerId: widget.providerId,
      customerName:
          FirebaseAuth.instance.currentUser?.displayName ?? "A customer",
    );
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking submitted! Provider will respond soon.'),
      ),
    );

    // TODO: Trigger FCM notification to provider
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _sendBookingNotification({
    required String providerId,
    required String customerName,
  }) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(providerId)
              .get();
      final fcmToken = userDoc.data()?['fcmToken'];
      print("FCM Token: $fcmToken");

      if (fcmToken == null || fcmToken.isEmpty) {
        print("No FCM token found for provider: $providerId");
        return;
      }

      final firebaseService = FirebaseService();
      await firebaseService.sendNotification(
        fcmToken: fcmToken,
        title: "New Booking Received!",
        body:
            "You have a new booking from $customerName for ${widget.serviceName}.",
      );
    } catch (e) {
      print("Error sending booking notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Book ${widget.serviceName}', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.white),
                          title: Text(
                            'Provider: $_providerName',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.build, color: Colors.white),
                          title: Text(
                            'Service: ${widget.serviceName}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(height: 32),

                      TextFormField(
                        controller: _addressController,
                        cursorColor: Colors.black,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Your Address',
                          labelStyle: const TextStyle(color: Colors.black),
                          border: const OutlineInputBorder(),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          prefixIcon: GestureDetector(
                            onTap: () async {
                              // Push screen and wait for address
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => LocationPickerScreen(
                                        onLocationPicked: (address, lat, lng) {
                                          setState(() {
                                            _addressController.text = address;
                                          });
                                        },
                                      ),
                                ),
                              );

                              if (result != null && result is String) {
                                setState(() {
                                  _addressController.text = result;
                                });
                              }
                            },
                            child: const Icon(Icons.location_on),
                          ),

                          prefixIconColor: Colors.black,
                        ),
                        onTapOutside:
                            (event) => FocusScope.of(context).unfocus(),
                        validator:
                            (val) => val!.isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _notesController,
                        cursorColor: Colors.black,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          prefixIcon: Icon(Icons.note_alt),
                          prefixIconColor: Colors.black,
                        ),
                        onTapOutside:
                            (event) => FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 16),

                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        title: Text(
                          _selectedDate == null
                              ? 'Choose Preferred Date'
                              : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today,
                          color: Colors.black,
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),

                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        title: Text(
                          _selectedTime == null
                              ? 'Choose Preferred Time'
                              : 'Time: ${_selectedTime!.format(context)}',
                          style: const TextStyle(color: Colors.black),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Colors.black,
                        ),
                        onTap: _pickTime,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitBooking,
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            'Submit Booking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
