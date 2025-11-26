import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniproject6/pages/Customer/booking_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/provider_model.dart';
import 'provider_detail_screen.dart';
import '/firebase_service.dart';

class ProviderListScreen extends StatefulWidget {
  final String category;

  const ProviderListScreen({super.key, required this.category});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firebaseService.requestPermission();
      await _firebaseService.saveTokenToFirestore(user.uid);
    }
    _firebaseService.initFCMListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("${widget.category} Providers"),
        backgroundColor: Colors.orange,
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('providers')
                .where('servicesOffered', arrayContains: widget.category)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No providers available",
                style: TextStyle(color: Colors.black, fontSize: 18)));
          }

          final providers =
              snapshot.data!.docs
                  .map((doc) => ProviderModel.fromFirestore(doc))
                  .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              return ProviderCard(
                provider: providers[index],
                providerId: providers[index].id,
                selectedCategory: widget.category,
              );
            },
          );
        },
      ),
    );
  }
}

class ProviderCard extends StatefulWidget {
  final ProviderModel provider;
  final String providerId;
  final String selectedCategory;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.providerId,
    required this.selectedCategory,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  Map<String, dynamic>? _serviceData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceData();
  }

  Future<void> _fetchServiceData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(widget.providerId)
            .collection('services')
            .doc(widget.selectedCategory)
            .get();

    setState(() {
      _serviceData = doc.data();
      _loading = false;
    });
  }

  String _getField(String key, String fallback) {
    final val = _serviceData?[key];
    return (val != null && val.toString().trim().isNotEmpty)
        ? val.toString()
        : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    final businessName = _getField('businessName', provider.businessName);
    final address = _getField('address', provider.address);
    final contact = _getField('contactNumber', provider.contactNumber);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProviderDetailScreen(
                  providerId: provider.userId,
                  selectedService: widget.selectedCategory,
                ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
                child: CachedNetworkImage(
                imageUrl: provider.image,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.2,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  size: 50,
                  color: Colors.red,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            address,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                provider.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final phone = contact;
                                    final uri = Uri.parse('tel:$phone');
                                    launchUrl(uri);
                                  },
                                  icon: const Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text("Call", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => BookingFormScreen(
                                              providerId: provider.userId,
                                              providerName: businessName,
                                              serviceName:
                                                  widget.selectedCategory,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.book_online,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text("Book Now", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
