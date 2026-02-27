import 'dart:async';
import 'package:flutter/material.dart';
import 'package:attendance/models/app_notification_model.dart';
import 'package:attendance/services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AppNotificationModel> _notifications = [];
  final bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;
  String? _currentTargetUid;

  List<AppNotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start streaming notifications for a specific ID (UID or 'admin')
  void startStreaming(String targetUid) {
    if (_currentTargetUid == targetUid) return; // Prevent double-subscribing
    _currentTargetUid = targetUid;

    _subscription?.cancel();
    _subscription = _firestoreService
        .streamNotifications(targetUid)
        .listen(
          (notifs) {
            _notifications = notifs;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load notifications';
            notifyListeners();
          },
        );
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String docId) async {
    try {
      await _firestoreService.markNotificationRead(docId);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentTargetUid == null) return;
    try {
      await _firestoreService.markAllNotificationsRead(_currentTargetUid!);
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
