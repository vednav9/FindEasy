import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'review_model.dart';

class ProviderModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String businessName;
  final String contactNumber;
  final String address;
  final List<String> servicesOffered;
  final String image;
  final String description;
  final double rating;
  final String verificationStatus;
  final Timestamp createdAt;
  final GeoPoint? location;
  final int bookingCount;
  final List<Review> reviews;

  ProviderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.businessName,
    required this.contactNumber,
    required this.address,
    required this.servicesOffered,
    required this.image,
    required this.description,
    required this.rating,
    required this.verificationStatus,
    required this.createdAt,
    this.location,
    this.bookingCount = 0,
    this.reviews = const [],
  });

  factory ProviderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      businessName: data['businessName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      servicesOffered: List<String>.from(data['servicesOffered'] ?? []),
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      verificationStatus: data['verificationStatus'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      location: data['location'],
      bookingCount: data['bookingCount'] ?? 0,
    );
  }

  double distanceFrom(GeoPoint userLocation) {
    if (location == null) return double.infinity;
    return Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      location!.latitude,
      location!.longitude,
    );
  }


  ProviderModel copyWith({List<Review>? reviews}) {
    return ProviderModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      businessName: businessName,
      contactNumber: contactNumber,
      address: address,
      servicesOffered: servicesOffered,
      image: image,
      description: description,
      rating: rating,
      verificationStatus: verificationStatus,
      createdAt: createdAt,
      location: location,
      bookingCount: bookingCount,
      reviews: reviews ?? this.reviews,
    );
  }
}
