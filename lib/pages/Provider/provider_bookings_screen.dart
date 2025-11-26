import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:miniproject6/pages/Provider/provider_booking_details_screen.dart';

import '../../login_screen.dart';
import '../../main.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];
  String _selectedStatus = 'All';
  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view bookings")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.09,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BottomNavBarWrapper(
                          userType: "provider",
                          initialIndex: 3,
                        ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage:
                    _user?.photoURL != null
                        ? NetworkImage(_user!.photoURL!)
                        : const AssetImage('assets/login_background.png')
                            as ImageProvider,
                radius: 23,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Manage Bookings",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusChips(),
          const Divider(height: 1, color: Colors.grey),
          Expanded(child: _buildBookingList()),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _statusOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            final status = _statusOptions[index];
            final selected = status == _selectedStatus;
            return ChoiceChip(
              label: Text(
                status,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              selectedColor: Colors.deepOrange,
              backgroundColor: Colors.grey[300],
              onSelected: (_) => setState(() => _selectedStatus = status),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    final baseQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: currentUser!.uid);

    final query =
        _selectedStatus != 'All'
            ? baseQuery.where(
              'status',
              isEqualTo: _selectedStatus.toLowerCase(),
            )
            : baseQuery;

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return const Center(child: Text("No bookings found", style: TextStyle(color: Colors.grey, fontSize: 18)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderBookingDetailScreen(bookingId: doc.id),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['customerName'] ?? 'Unknown Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("Service: ${data['serviceName']}", style: TextStyle(color: Colors.white),),
                      Text("Date: ${data['date']}  •  Time: ${data['time']}", style: TextStyle(color: Colors.white),),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(data['status']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['status'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blueGrey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
