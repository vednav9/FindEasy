import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Request permission for iOS devices
  Future<void> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        kDebugMode) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Get and save the FCM token to Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({'fcmToken': token});
        print('FCM token updated');

        await _firebaseMessaging.subscribeToTopic('special_offers');
        print('✅ Subscribed to special_offers topic');
      } else {
        print("Token was null");
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> unsubscribeFromTopicsOnLogout() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('special_offers');
      print('✅ Unsubscribed from special_offers topic');
    } catch (e) {
      print('Error unsubscribing: $e');
    }
  }

  Future<void> setupFlutterNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    final accessToken = await getAccessToken();
    const projectId = 'findeasy-6abd3';

    final url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final message = {
      'message': {
        'token': fcmToken,
        'notification': {'title': title, 'body': body},
        'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
      },
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(message), // ✅ Fix: JSON encoding here
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${response.body}");
      } else {
        print(
          "❌ Failed to send notification: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Exception while sending FCM: $e");
    }
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = jsonDecode(
      await rootBundle.loadString('assets/service_account.json'),
    );
    final accountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = client.credentials.accessToken.data;

    client.close();
    print('Access token: $accessToken');
    return accessToken;
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final userId = _auth.currentUser!.uid;
    final bookingRef = _db.collection('bookings').doc(bookingId);
    final bookingSnapshot = await bookingRef.get();

    if (!bookingSnapshot.exists) {
      print("❌ Booking not found: $bookingId");
      return;
    }

    final bookingData = bookingSnapshot.data()!;
    final customerId = bookingData['customerId'];
    final providerId = bookingData['providerId'];
    final serviceName = bookingData['serviceName'];

    // Determine the other user to notify
    final recipientId = userId == customerId ? providerId : customerId;

    // Fetch recipient FCM token
    final userDoc = await _db.collection('users').doc(recipientId).get();
    final fcmToken = userDoc.data()?['fcmToken'];

    if (fcmToken == null || fcmToken.isEmpty) {
      print("❌ No FCM token found for user: $recipientId");
    } else {
      final String title = "Booking Status Updated";
      final String body = "The booking was $newStatus for $serviceName.";

      await sendNotification(fcmToken: fcmToken, title: title, body: body);
    }

    // Finally update Firestore
    await bookingRef.update({
      'status': newStatus,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print("✅ Booking updated and notification sent");
  }

  // Initialize FCM listeners
  void initFCMListeners() {
    void showLocalNotification(RemoteNotification notification) async {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'default_channel',
            'General',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        platformChannelSpecifics,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification!.title}');
      if (message.notification != null) {
        showLocalNotification(message.notification!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        print(
          'Notification clicked (background): ${message.notification!.title}',
        );
      } else {
        print('App opened via message without notification payload');
      }
    });

    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      if (message.notification != null) {
        print('Background notification: ${message.notification!.title}');
      } else {
        print('Background message received with no notification payload');
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _db.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
          });
          print('FCM token updated successfully: $newToken');
        } catch (e) {
          print('Error updating FCM token: $e');
        }
      }
    });
  }
}
