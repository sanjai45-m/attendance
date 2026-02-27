import 'dart:async';
import 'package:flutter/material.dart';
import 'package:attendance/models/leave_request_model.dart';
import 'package:attendance/models/app_notification_model.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/core/enums/attendance_status.dart';
import 'package:attendance/services/firestore_service.dart';
import 'package:attendance/services/telegram_service.dart';
import 'package:attendance/services/fcm_service.dart';

class LeaveProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final TelegramService _telegramService = TelegramService();
  final FCMService _fcmService = FCMService();

  List<LeaveRequestModel> _myRequests = [];
  List<LeaveRequestModel> _allRequests = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _myRequestsSub;
  StreamSubscription? _allRequestsSub;

  List<LeaveRequestModel> get myRequests => _myRequests;
  List<LeaveRequestModel> get allRequests => _allRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start streaming employee's own requests
  void startStreamingMyRequests(String uid) {
    _myRequestsSub?.cancel();
    _myRequestsSub = _firestoreService
        .streamMyLeaveRequests(uid)
        .listen(
          (requests) {
            _myRequests = requests;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load your leave requests';
            notifyListeners();
          },
        );
  }

  /// Start streaming all requests (for Admin)
  void startStreamingAllRequests() {
    _allRequestsSub?.cancel();
    _allRequestsSub = _firestoreService.streamAllLeaveRequests().listen(
      (requests) {
        _allRequests = requests;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load all leave requests';
        notifyListeners();
      },
    );
  }

  /// Submit a new leave request (Employee)
  Future<bool> submitLeaveRequest({
    required String uid,
    required String employeeId,
    required String employeeName,
    required String date,
    required String type,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LeaveRequestModel(
        uid: uid,
        employeeId: employeeId,
        employeeName: employeeName,
        date: date,
        type: type,
        reason: reason,
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createLeaveRequest(request);

      // Send notification to Admin
      await _firestoreService.sendNotification(
        AppNotificationModel(
          targetUid: 'admin',
          title: 'New Leave Request',
          message: '$employeeName formally requested leave on $date ($type).',
          type: 'LeaveRequest',
          createdAt: DateTime.now(),
        ),
      );

      // Send Telegram notification
      final settings = await _firestoreService.getSettings();
      if (settings.isTelegramConfigured) {
        final msg =
            '🔔 *New Leave Request*\n'
            'Employee: $employeeName\n'
            'Date: $date\n'
            'Type: $type\n'
            'Reason: ${reason ?? "N/A"}\n'
            'Status: Pending';
        await _telegramService.sendMessage(
          botToken: settings.telegramBotToken,
          chatId: settings.telegramChatId,
          message: msg,
        );
      }

      // Send FCM push notification to admins
      await _fcmService.sendPunchNotification(
        title: 'New Leave Request',
        body: '$employeeName formally requested leave on $date ($type).',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to submit leave request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update a leave request status (Admin)
  Future<bool> updateRequestStatus(
    LeaveRequestModel request,
    String newStatus,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateLeaveRequestStatus(request.id!, newStatus);

      // If approved, create a dummy Attendance record for that day
      if (newStatus == 'Approved') {
        final attendance = AttendanceModel(
          uid: request.uid,
          employeeId: request.employeeId,
          employeeName: request.employeeName,
          date: request.date,
          status: AttendanceStatus.onLeave,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createAttendance(attendance);
      }

      // Notify the employee (In-App)
      await _firestoreService.sendNotification(
        AppNotificationModel(
          targetUid: request.uid,
          title: 'Leave Request $newStatus',
          message:
              'Your request for leave on ${request.date} has been officially $newStatus.',
          type: 'LeaveResult',
          createdAt: DateTime.now(),
        ),
      );

      // Notify the employee (FCM Push)
      await _fcmService.sendUserNotification(
        uid: request.uid,
        title: 'Leave Request $newStatus',
        body:
            'Your request for leave on ${request.date} has been officially $newStatus.',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update status';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _myRequestsSub?.cancel();
    _allRequestsSub?.cancel();
    super.dispose();
  }
}
