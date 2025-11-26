import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../firebase_service.dart';
import '../../models/provider_model.dart';
import '../../models/review_model.dart';
import 'booking_form_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final String selectedService;

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    required this.selectedService,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProviderModel? _provider;
  bool _isLoading = true;
  double _newRating = 0;
  final _commentController = TextEditingController();
  Map<String, dynamic>? _serviceData;
  List<String> _serviceImages = [];

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final providerDoc =
        await _db.collection('providers').doc(widget.providerId).get();
    final serviceDoc =
        await _db
            .collection('providers')
            .doc(widget.providerId)
            .collection('services')
            .doc(widget.selectedService)
            .get();

    final reviewsSnapshot =
        await providerDoc.reference
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .get();

    final provider = ProviderModel.fromFirestore(providerDoc);
    final reviews =
        reviewsSnapshot.docs.map((e) => Review.fromMap(e.data())).toList();

    final serviceImages =
        (serviceDoc.data()?['images'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];

    setState(() {
      _provider = provider.copyWith(reviews: reviews);
      _serviceData = serviceDoc.data(); // Service-specific data
      _serviceImages = serviceImages;
      _isLoading = false;
    });
  }

  Future<void> _submitReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reviewerName = user.displayName ?? "Anonymous";

    final newReview = {
      'userId': user.uid,
      'reviewerName': reviewerName,
      'rating': _newRating,
      'comment': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('providers')
        .doc(_provider!.userId)
        .collection('reviews')
        .add(newReview);

    _commentController.clear();
    _newRating = 0;

    await _loadProvider();
    await _updateAverageRating();
    await _sendReviewNotification();
  }

  Future<void> _sendReviewNotification() async {
    try {
      final providerDoc =
          await _db.collection('users').doc(_provider!.userId).get();

      final fcmToken = providerDoc.data()?['fcmToken'];
      final reviewerName = _auth.currentUser?.displayName ?? "Someone";

      if (fcmToken == null || fcmToken.isEmpty) {
        print("No FCM token found for provider: ${_provider!.userId}");
        return;
      }

      final firebaseService = FirebaseService();
      await firebaseService.sendNotification(
        fcmToken: fcmToken,
        title: "New Review Received",
        body: "$reviewerName left you a review!",
      );
    } catch (e) {
      print("Failed to send review notification: $e");
    }
  }

  Future<void> _updateAverageRating() async {
    final snapshot =
        await _db
            .collection('providers')
            .doc(_provider!.userId)
            .collection('reviews')
            .get();

    if (snapshot.docs.isEmpty) return;

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['rating'] ?? 0).toDouble();
    }
    final avg = total / snapshot.docs.length;

    await _db.collection('providers').doc(_provider!.userId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
    });
  }

  Future<void> _launchPhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone call')),
      );
    }
  }

  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingFormScreen(
              providerId: _provider!.userId,
              providerName: _provider!.businessName,
              serviceName: widget.selectedService,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _provider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final businessName = _getField('businessName', _provider!.businessName);
    final address = _getField('address', _provider!.address);
    final contact = _getField('contactNumber', _provider!.contactNumber);
    final description = _getField('description', _provider!.description);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(businessName),
        backgroundColor: Colors.orange,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _provider!.image,
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      businessName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          _provider!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Lato',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(color: Colors.black45, height: 40),
                    _buildInfoRow("Contact", contact),
                    _buildInfoRow("Address", address),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () =>
                                    _launchPhoneCall(_provider!.contactNumber),
                            icon: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Call",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _navigateToBooking,
                            icon: const Icon(
                              Icons.book_online,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Book Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_serviceImages.isNotEmpty) ...[
                      const Divider(color: Colors.black45, height: 40),
                      const Text(
                        "Photos",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _serviceImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(_serviceImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const Divider(color: Colors.black45, height: 40),

                    const Text(
                      "Services Offered",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children:
                          _provider!.servicesOffered.map((service) {
                            return Chip(
                              label: Text(
                                service,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              backgroundColor: Colors.orange,
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                    ),

                    const Divider(color: Colors.black45, height: 40),

                    const Text(
                      "Reviews",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),

                    const SizedBox(height: 10),

                    ..._provider!.reviews.map((r) => _buildReviewCard(r)),

                    const SizedBox(height: 20),

                    _auth.currentUser != null
                        ? _buildReviewForm()
                        : const Text(
                          "Login to leave a review",
                          style: TextStyle(color: Colors.white70),
                        ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  String _getField(String key, String fallback) {
    final val = _serviceData?[key];
    return (val != null && val.toString().trim().isNotEmpty)
        ? val.toString()
        : fallback;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lato',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          review.reviewerName,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review.comment, style: const TextStyle(color: Colors.white70)),
            Row(
              children: List.generate(
                review.rating.toInt(),
                (index) =>
                    const Icon(Icons.star, color: Colors.orange, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Write a Review",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Lato',
          ),
        ),
        const SizedBox(height: 10),
        Slider(
          value: _newRating,
          min: 0,
          max: 5,
          divisions: 5,
          label: _newRating.toString(),
          onChanged: (value) {
            setState(() {
              _newRating = value;
            });
          },
        ),
        TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your review",
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              "Submit Review",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
