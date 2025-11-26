import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:miniproject6/firebase_service.dart';

import '../../login_screen.dart';
import '../../main.dart';
import '../../models/category_model.dart';
import '../../widgets/category_card.dart';
import 'provider_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late User? _user;
  late String displayName = "";

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadDisplayName();

    // Initialize FCM via service only
    _firebaseService.requestPermission();
    _firebaseService.initFCMListeners();

    if (_user != null) {
      _firebaseService.saveTokenToFirestore(widget.userId);
    }
  }

  Future<void> _loadDisplayName() async {
    if (_user != null) {
      final methods =
          _user!.providerData.map((info) => info.providerId).toList();

      if (methods.contains("password")) {
        // Email/password login, get name from Firestore
        DocumentSnapshot userDoc =
            await _db.collection("users").doc(widget.userId).get();
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          displayName = data?["name"] ?? "User";
        });
      } else {
        // Google Sign-In
        setState(() {
          displayName = _user!.displayName ?? "User";
        });
      }
    }
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _signOut(context);
              },
              child: Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    // Redirect to login screen and clear navigation stack
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false, // Removes all previous screens
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.09,

        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BottomNavBarWrapper(
                          userType: "customer",
                          initialIndex: 3, // Open ProfileScreen
                        ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage:
                      _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : AssetImage('assets/login_background.png')
                              as ImageProvider,
                  radius: 23,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Hello, $displayName",
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
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Special Offers",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 10),

            SpecialOffersCarousel(), // ✅ Inserted here

            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Categories",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount:
                    categoryList.length, // Use the list length dynamically
                itemBuilder: (context, index) {
                  final category = categoryList[index];
                  return CategoryCard(
                    icon: category.icon,
                    title: category.title,
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Recommended Services",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 10),

            _buildRecommendedProviders(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProviders() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection("bookings")
              .where("customerId", isEqualTo: userId)
              .orderBy("timestamp", descending: true)
              .limit(20)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final Map<String, int> providerFrequency = {};

        for (var doc in bookings) {
          final data = doc.data() as Map<String, dynamic>;
          final providerId = data['providerId'];
          if (providerId != null) {
            providerFrequency[providerId] =
                (providerFrequency[providerId] ?? 0) + 1;
          }
        }

        final sortedProviderIds =
            providerFrequency.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        final topProviderIds =
            sortedProviderIds.take(5).map((entry) => entry.key).toList();

        if (topProviderIds.isEmpty) {
          return const Center(child: Text("No recommendations available"));
        }

        return FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection("providers")
                  .where(FieldPath.documentId, whereIn: topProviderIds)
                  .get(),
          builder: (context, providerSnapshot) {
            if (!providerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final providerDocs = providerSnapshot.data!.docs;

            return Column(
              children:
                  providerDocs.map((provider) {
                    final data = provider.data() as Map<String, dynamic>;
                    final services = (data["servicesOffered"] as List).join(
                      ", ",
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(data["image"] ?? ''),
                          radius: 30,
                        ),
                        title: Text(data["businessName"] ?? "Unknown"),
                        subtitle: Text(
                          services,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProviderDetailScreen(
                                    providerId: provider.id,
                                    selectedService:
                                        data["servicesOffered"].isNotEmpty
                                            ? data["servicesOffered"].first
                                            : '',
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            );
          },
        );
      },
    );
  }
}

class SpecialOffersCarousel extends StatefulWidget {
  const SpecialOffersCarousel({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SpecialOffersCarouselState createState() => _SpecialOffersCarouselState();
}

class _SpecialOffersCarouselState extends State<SpecialOffersCarousel> {
  List<Map<String, dynamic>> offers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    FirebaseFirestore.instance.collection('offers').get().then((querySnapshot) {
      List<Map<String, dynamic>> tempOffers = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data(); // Ensure correct type
        tempOffers.add({
          "id": doc.id,
          "imagePath": data["image"] ?? "",
          "title": data["title"] ?? "No Title",
          "offerDetails": data["description"] ?? "No Description",
          "validity": data["validity"] ?? "Limited Time Offer",
          "terms":
              (data["terms"] is List<dynamic>)
                  ? List<String>.from(
                    data["terms"].map((item) => item.toString()),
                  )
                  : [], // If terms is missing or not a List, set empty list
          "rating":
              (data["rating"] is num)
                  ? (data["rating"] as num).toInt()
                  : 0.0, // Default rating if missing
          "reviews":
              (data["reviews"] is List<dynamic>)
                  ? List<Map<String, dynamic>>.from(
                    data["reviews"].map(
                      (review) => Map<String, dynamic>.from(review),
                    ),
                  )
                  : [], // If reviews is missing or not a List, set empty list
        });
      }

      setState(() {
        offers = tempOffers;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child:
          isLoading
              ? Center(child: CircularProgressIndicator()) // Loading indicator
              : CarouselSlider(
                items:
                    offers.map((offer) {
                      return offerCard(
                        context,
                        offer["id"],
                        offer["imagePath"],
                        offer["title"],
                        offer["offerDetails"],
                        offer["validity"],
                        offer["terms"],
                        offer["rating"],
                        offer["reviews"],
                      );
                    }).toList(),
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.25,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  viewportFraction: 0.85,
                ),
              ),
    );
  }

  Widget offerCard(
    BuildContext context,
    String id,
    String imagePath,
    String title,
    String offerDetails,
    String validity,
    List<String> terms,
    int rating,
    List<Map<String, dynamic>> reviews,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          "/special_offer",
          arguments: {
            "id": id,
            "imagePath": imagePath,
            "title": title,
            "offerDetails": offerDetails,
            "validity": validity,
            "terms": terms,
            "rating": rating,
            "reviews": reviews,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
            placeholder:
                (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
