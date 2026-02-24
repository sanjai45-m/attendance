import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:attendance/core/constants/firestore_paths.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request notification permission
  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Get FCM device token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Listen for token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Save FCM token to user's Firestore document
  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(uid)
            .update({'fcmToken': token});
        debugPrint('[FCMService] Token saved for user $uid');
      }
    } catch (e) {
      debugPrint('[FCMService] Error saving token: $e');
    }
  }

  /// Listen for token refresh and update Firestore
  void listenForTokenRefresh(String uid) {
    onTokenRefresh.listen((newToken) async {
      await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .update({'fcmToken': newToken});
      debugPrint('[FCMService] Token refreshed for user $uid');
    });
  }

  /// Get all admin FCM tokens from Firestore
  Future<List<String>> getAdminTokens() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'admin')
          .get();

      final tokens = <String>[];
      for (final doc in snapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
      debugPrint('[FCMService] Found ${tokens.length} admin tokens');
      return tokens;
    } catch (e) {
      debugPrint('[FCMService] Error getting admin tokens: $e');
      return [];
    }
  }

  /// Send push notification to admins when employee punches in/out
  Future<void> sendPunchNotification({
    required String title,
    required String body,
    required String serverKey,
  }) async {
    try {
      final adminTokens = await getAdminTokens();
      if (adminTokens.isEmpty) {
        debugPrint('[FCMService] No admin tokens found, skipping push');
        return;
      }

      for (final token in adminTokens) {
        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': token,
            'notification': {
              'title': title,
              'body': body,
              'sound': 'default',
            },
            'priority': 'high',
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'punch_event',
            },
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('[FCMService] Push notification sent successfully');
        } else {
          debugPrint('[FCMService] Push failed: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('[FCMService] Error sending push: $e');
    }
  }

  /// Setup foreground message handler
  void setupForegroundHandler(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Setup background message handler (must be top-level function)
  static void setupBackgroundHandler(
      Future<void> Function(RemoteMessage) handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
