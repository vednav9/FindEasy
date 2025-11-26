import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../firebase_service.dart';

class ProviderBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const ProviderBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<ProviderBookingDetailScreen> createState() =>
      _ProviderBookingDetailScreenState();
}

class _ProviderBookingDetailScreenState
    extends State<ProviderBookingDetailScreen> {
  Map<String, dynamic>? bookingData;
  bool isLoading = true;
  bool _isUpdating = false;
  DateTime? _newDate;
  TimeOfDay? _newTime;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .get();

    if (doc.exists) {
      setState(() {
        bookingData = doc.data();
        isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Change Status"),
            content: Text(
              "Are you sure you want to mark this booking as $status?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final firebaseService = FirebaseService();
      await firebaseService.updateBookingStatus(widget.bookingId, status);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Status updated to $status")));

      await _fetchBookingDetails(); // Refresh
    }
  }

  Future<void> _fetchBooking() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .get();

    setState(() {
      bookingData = doc.data();
      isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (picked != null) setState(() => _newDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _newTime = picked);
  }

  Future<void> _rescheduleBooking() async {
    if (_newDate == null || _newTime == null) return;

    setState(() => _isUpdating = true);

    final formattedDate = _newDate!.toIso8601String().split('T')[0];
    final formattedTime = _newTime!.format(context);
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId);

    final bookingSnapshot = await bookingRef.get();
    final bookingData = bookingSnapshot.data()!;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'date': formattedDate, 'time': formattedTime});

    // Send notification to provider
    final providerId = bookingData['providerId'];
    final service = FirebaseService();
    final providerDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();
    final fcmToken = providerDoc.data()?['fcmToken'];

    if (fcmToken != null && fcmToken.isNotEmpty) {
      await service.sendNotification(
        fcmToken: fcmToken,
        title: 'Booking Rescheduled',
        body:
            '${bookingData['customerName']} rescheduled the booking to $formattedDate at $formattedTime',
      );
    }

    await _fetchBooking();

    setState(() => _isUpdating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking rescheduled successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || bookingData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = bookingData!;
    final status = data['status'] ?? '';
    final isCancelled = status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard("Customer Name", data['customerName']),
              _buildSectionCard("Service", data['serviceName']),
              _buildSectionCard("Date", data['date']),
              _buildSectionCard("Time", data['time']),
              _buildSectionCard("Address", data['address']),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                _buildSectionCard("Notes", data['notes']),
              _buildStatusBadge(status, isCancelled),
              const SizedBox(height: 25),
              if (!isCancelled &&
                  (status == 'pending' || status == 'confirmed'))
                _buildUpdateButtons(),
              if (!isCancelled &&
                  (status == 'pending' || status == 'confirmed'))
                _buildRescheduleSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isCancelled) {
    final color =
        isCancelled
            ? Colors.red
            : status == 'completed'
            ? Colors.green
            : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Chip(
        backgroundColor: color.withValues(alpha: .1),
        shape: StadiumBorder(side: BorderSide(color: color)),
        avatar: Icon(Icons.info, size: 20, color: color),
        label: Text(
          "Status: ${status.toUpperCase()}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildUpdateButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _changeStatus("confirmed"),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("Confirm"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _changeStatus("completed"),
                icon: const Icon(Icons.done_all, color: Colors.white),
                label: const Text("Complete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: ElevatedButton.icon(
            onPressed: () => _changeStatus("cancelled"),
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text("Cancel"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildRescheduleSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reschedule Booking",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      _newDate == null
                          ? "Pick Date"
                          : _newDate!.toString().split(' ')[0],
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, color: Colors.white),
                    label: Text(
                      _newTime == null
                          ? "Pick Time"
                          : _newTime!.format(context),
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rescheduleBooking,
                    icon: const Icon(Icons.save, size: 18, color: Colors.white),
                    label: const Text(
                      "Update Booking",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
