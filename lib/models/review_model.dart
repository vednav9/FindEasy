import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime timestamp;

  Review({
    required this.userId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      userId: data['userId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }
}
