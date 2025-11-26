import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SpecialOfferScreen extends StatelessWidget {
  final String id;
  final String imagePath;
  final String title;
  final String offerDetails;
  final String validity;
  final List<String> terms;
  final int rating;
  final List<Map<String, dynamic>> reviews;

  const SpecialOfferScreen({
    super.key,
    required this.id,
    required this.imagePath,
    required this.title,
    required this.offerDetails,
    required this.validity,
    required this.terms,
    required this.rating,
    required this.reviews,
  });

  void _availOfferOnce(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please sign in to avail this offer.")),
      );
      return;
    }

    final offerRef = FirebaseFirestore.instance
        .collection('user_availed_offers')
        .where('userId', isEqualTo: user.uid)
        .where('offerId', isEqualTo: id);

    final existing = await offerRef.get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You’ve already availed this offer.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('user_availed_offers').add({
      'userId': user.uid,
      'offerId': id,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Offer availed successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Special Offer"),
        backgroundColor: Colors.orange,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offer Image
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: imagePath,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const Divider(height: 32),

            // Offer Details
            Text(
              offerDetails,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const Divider(height: 32),

            // Validity
            Row(
              children: [
                Icon(Icons.timer, color: Colors.redAccent),
                SizedBox(width: 5),
                Text(
                  validity,
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 15),

            // Terms & Conditions
            Text(
              "Terms & Conditions:",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
            ),
            SizedBox(height: 5),
            ...terms.map(
              (term) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 5),
                    Expanded(child: Text(term, style: TextStyle(color: Colors.black, fontSize: 16))),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),

            // Ratings
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 5),
                Text(
                  "$rating/5",
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            SizedBox(height: 15),

            // Reviews Section
            Text(
              "Customer Reviews:",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lato'),
            ),
            ...reviews.map(
              (review) => ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage('assets/offer_review_placeholder_image_1.png'),),
                title: Text(
                  review["user"],
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(review["comment"], style: TextStyle(color: Colors.black87)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    review["stars"],
                    (index) => Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Avail Offer Button
            Center(
              child: ElevatedButton(
                onPressed: () => _availOfferOnce(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  "Avail Offer",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
