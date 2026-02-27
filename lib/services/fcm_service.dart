import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:attendance/core/constants/firestore_paths.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request notification permission
  Future<void> requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
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
        await _firestore.collection(FirestorePaths.users).doc(uid).update({
          'fcmToken': token,
        });
        debugPrint('[FCMService] Token saved for user $uid');
      }
    } catch (e) {
      debugPrint('[FCMService] Error saving token: $e');
    }
  }

  /// Listen for token refresh and update Firestore
  void listenForTokenRefresh(String uid) {
    onTokenRefresh.listen((newToken) async {
      await _firestore.collection(FirestorePaths.users).doc(uid).update({
        'fcmToken': newToken,
      });
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

  /// Get OAuth2 access token using service account
  Future<String?> _getAccessToken() async {
    try {
      final serviceAccountJson = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(credentials, scopes);
      final token = authClient.credentials.accessToken.data;
      authClient.close();

      return token;
    } catch (e) {
      debugPrint('[FCMService] Error getting access token: $e');
      return null;
    }
  }

  /// Get Firebase project ID from service account
  Future<String?> _getProjectId() async {
    try {
      final serviceAccountJson = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final data = jsonDecode(serviceAccountJson) as Map<String, dynamic>;
      return data['project_id'] as String?;
    } catch (e) {
      debugPrint('[FCMService] Error getting project ID: $e');
      return null;
    }
  }

  /// Send push notification to admins using FCM v1 API
  Future<void> sendPunchNotification({
    required String title,
    required String body,
  }) async {
    try {
      final adminTokens = await getAdminTokens();
      if (adminTokens.isEmpty) {
        debugPrint('[FCMService] No admin tokens found, skipping push');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('[FCMService] Failed to get access token');
        return;
      }

      final projectId = await _getProjectId();
      if (projectId == null) {
        debugPrint('[FCMService] Failed to get project ID');
        return;
      }

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      for (final token in adminTokens) {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {'title': title, 'body': body},
              'android': {
                'priority': 'HIGH',
                'notification': {
                  'channel_id': 'attendance_notifications',
                  'sound': 'default',
                },
              },
            },
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('[FCMService] Push notification sent successfully');
        } else {
          debugPrint(
            '[FCMService] Push failed (${response.statusCode}): ${response.body}',
          );
        }
      }
    } catch (e) {
      debugPrint('[FCMService] Error sending push: $e');
    }
  }

  /// Send push notification to a specific user using FCM v1 API
  Future<void> sendUserNotification({
    required String uid,
    required String title,
    required String body,
  }) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .get();
      final token = doc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) {
        debugPrint('[FCMService] No token found for user $uid, skipping push');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final projectId = await _getProjectId();
      if (projectId == null) return;

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'attendance_notifications',
                'sound': 'default',
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCMService] User push notification sent successfully');
      } else {
        debugPrint(
          '[FCMService] User push failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[FCMService] Error sending user push: $e');
    }
  }

  /// Setup foreground message handler
  void setupForegroundHandler(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  /// Setup background message handler (must be top-level function)
  static void setupBackgroundHandler(
    Future<void> Function(RemoteMessage) handler,
  ) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
