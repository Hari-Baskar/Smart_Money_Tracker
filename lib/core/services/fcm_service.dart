import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Fetch FCM token and register refresh listener silently, 
      // without popping up standard push notification permissions
      await _updateFCMToken();

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      debugPrint('Error initializing FCM Service: $e');
    }
  }

  static Future<void> _updateFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint('FCM Token saved to Firestore');
      } catch (e) {
        debugPrint('Error saving FCM token to Firestore: $e');
      }
    }
  }
}
