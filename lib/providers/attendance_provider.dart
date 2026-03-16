import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/models/app_settings_model.dart';
import 'package:attendance/models/app_notification_model.dart';
import 'package:attendance/core/enums/attendance_status.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/services/firestore_service.dart';
import 'package:attendance/services/telegram_service.dart';
import 'package:attendance/services/fcm_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final TelegramService _telegramService = TelegramService();
  final FCMService _fcmService = FCMService();

  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _myHistory = [];
  List<AttendanceModel> _dailyAttendance = [];
  List<AttendanceModel> _reportData = [];
  bool _isLoading = false;
  bool _isPunching = false;
  String? _error;
  String _selectedDate = AppDateUtils.todayString();
  StreamSubscription? _historySubscription;
  StreamSubscription? _dailySubscription;

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get myHistory => _myHistory;
  List<AttendanceModel> get dailyAttendance => _dailyAttendance;
  List<AttendanceModel> get reportData => _reportData;
  bool get isLoading => _isLoading;
  bool get isPunching => _isPunching;
  String? get error => _error;
  String get selectedDate => _selectedDate;

  bool get canPunchIn =>
      _todayAttendance == null || !_todayAttendance!.hasPunchedIn;
  bool get canPunchOut =>
      _todayAttendance != null &&
      _todayAttendance!.hasPunchedIn &&
      !_todayAttendance!.hasPunchedOut &&
      _todayAttendance!.status != AttendanceStatus.onLeave;
  bool get isOnLeave =>
      _todayAttendance != null &&
      _todayAttendance!.status == AttendanceStatus.onLeave;

  /// Load today's attendance for the current employee
  Future<void> loadTodayAttendance(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todayAttendance = await _firestoreService.getTodayAttendance(
        uid,
        AppDateUtils.todayString(),
      );
    } catch (e) {
      _error = 'Failed to load today\'s attendance.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Punch In
  Future<bool> punchIn({
    required String uid,
    required String employeeId,
    required String employeeName,
    required AppSettingsModel settings,
    required String location,
  }) async {
    _isPunching = true;
    _error = null;
    notifyListeners();

    try {
      // Check if already punched in
      final existing = await _firestoreService.getTodayAttendance(
        uid,
        AppDateUtils.todayString(),
      );

      if (existing != null && existing.hasPunchedIn) {
        _error = 'You have already punched in today.';
        _isPunching = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final isLate = AppDateUtils.isLate(
        now,
        settings.workStartTime,
        settings.lateThresholdMinutes,
      );

      final attendance = AttendanceModel(
        uid: uid,
        employeeId: employeeId,
        employeeName: employeeName,
        date: AppDateUtils.todayString(),
        punchIn: now,
        punchInLocation: location,
        status: isLate ? AttendanceStatus.late_ : AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.createAttendance(attendance);
      _todayAttendance = attendance;

      // Send in-app notification to Admin
      await _firestoreService.sendNotification(
        AppNotificationModel(
          targetUid: 'admin',
          title: '✅ Punch In',
          message:
              '$employeeName ($employeeId) punched in at ${AppDateUtils.toTimeString(now)}\nLocation: $location',
          type: 'PunchIn',
          createdAt: now,
        ),
      );

      // Send Telegram notification
      debugPrint(
        '[AttendanceProvider] Telegram configured: ${settings.isTelegramConfigured}',
      );
      debugPrint(
        '[AttendanceProvider] Bot token: ${settings.telegramBotToken.isNotEmpty ? "SET" : "EMPTY"}',
      );
      debugPrint(
        '[AttendanceProvider] Chat ID: ${settings.telegramChatId.isNotEmpty ? "SET" : "EMPTY"}',
      );
      if (settings.isTelegramConfigured) {
        final message = _telegramService.formatPunchInMessage(
          employeeName: employeeName,
          employeeId: employeeId,
          time: AppDateUtils.toTimeString(now),
        );
        // Append location
        final messageWithLocation = '$message\n📍 Location: $location';
        debugPrint('[AttendanceProvider] Sending Telegram message...');
        await _telegramService.sendMessage(
          botToken: settings.telegramBotToken,
          chatId: settings.telegramChatId,
          message: messageWithLocation,
        );
        debugPrint('[AttendanceProvider] Telegram message sent!');
      }

      // Send FCM push notification to admins
      await _fcmService.sendPunchNotification(
        title: '✅ Punch In',
        body:
            '$employeeName ($employeeId) punched in at ${AppDateUtils.toTimeString(now)} from $location',
      );

      _isPunching = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AttendanceProvider] PunchIn error: $e');
      _error = 'Failed to punch in. Please try again.';
      _isPunching = false;
      notifyListeners();
      return false;
    }
  }

  /// Punch Out
  Future<bool> punchOut({
    required String uid,
    required String employeeId,
    required String employeeName,
    required AppSettingsModel settings,
    required String location,
  }) async {
    _isPunching = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await _firestoreService.getTodayAttendance(
        uid,
        AppDateUtils.todayString(),
      );

      if (existing == null || !existing.hasPunchedIn) {
        _error = 'You haven\'t punched in yet today.';
        _isPunching = false;
        notifyListeners();
        return false;
      }

      if (existing.hasPunchedOut) {
        _error = 'You have already punched out today.';
        _isPunching = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final totalHours = AppDateUtils.calculateHours(existing.punchIn!, now);

      await _firestoreService.updateAttendance(existing.id!, {
        'punchOut': Timestamp.fromDate(now),
        'punchOutLocation': location,
        'totalHours': totalHours,
      });

      _todayAttendance = existing.copyWith(
        punchOut: now,
        punchOutLocation: location,
        totalHours: totalHours,
      );

      // Send in-app notification to Admin
      await _firestoreService.sendNotification(
        AppNotificationModel(
          targetUid: 'admin',
          title: '🔴 Punch Out',
          message:
              '$employeeName ($employeeId) punched out at ${AppDateUtils.toTimeString(now)} — Worked ${_todayAttendance!.totalHoursFormatted}\nLocation: $location',
          type: 'PunchOut',
          createdAt: now,
        ),
      );

      // Send Telegram notification
      if (settings.isTelegramConfigured) {
        final message = _telegramService.formatPunchOutMessage(
          employeeName: employeeName,
          employeeId: employeeId,
          time: AppDateUtils.toTimeString(now),
          totalHours: _todayAttendance!.totalHoursFormatted,
        );
        final messageWithLocation = '$message\n📍 Location: $location';
        await _telegramService.sendMessage(
          botToken: settings.telegramBotToken,
          chatId: settings.telegramChatId,
          message: messageWithLocation,
        );
      }

      // Send FCM push notification to admins
      await _fcmService.sendPunchNotification(
        title: '🔴 Punch Out',
        body:
            '$employeeName ($employeeId) punched out at ${AppDateUtils.toTimeString(now)} from $location — Worked ${_todayAttendance!.totalHoursFormatted}',
      );

      _isPunching = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to punch out. Please try again.';
      _isPunching = false;
      notifyListeners();
      return false;
    }
  }

  /// Stream employee's attendance history
  void loadMyHistory(String uid) {
    _historySubscription?.cancel();
    _error = null; // Clear stale errors
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint(
        '[AttendanceProvider] Skipping loadMyHistory — not authenticated',
      );
      return;
    }
    _historySubscription = _firestoreService
        .streamMyAttendance(uid)
        .listen(
          (list) {
            _myHistory = list;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[AttendanceProvider] History stream error: $e');
            _error = 'Failed to load attendance history.';
            notifyListeners();
          },
        );
  }

  /// Stream daily attendance (admin)
  void loadDailyAttendance(String date) {
    _selectedDate = date;
    _dailySubscription?.cancel();

    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint(
      '[AttendanceProvider] loadDailyAttendance called for date: $date',
    );
    debugPrint(
      '[AttendanceProvider] Current auth user: ${currentUser?.uid ?? "NULL"}',
    );

    if (currentUser == null) {
      debugPrint('[AttendanceProvider] Skipping — not authenticated');
      return;
    }

    // First try a one-time get() to test if the query works at all
    FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: date)
        .get()
        .then((snapshot) {
          debugPrint(
            '[AttendanceProvider] GET query succeeded! Found ${snapshot.docs.length} docs',
          );
          // If GET works, set up the stream
          _dailySubscription = _firestoreService
              .streamAttendanceByDate(date)
              .listen(
                (list) {
                  _dailyAttendance = list;
                  notifyListeners();
                },
                onError: (e) {
                  debugPrint('[AttendanceProvider] Stream error: $e');
                  _error = 'Failed to load daily attendance.';
                  notifyListeners();
                },
              );
        })
        .catchError((e) {
          debugPrint('[AttendanceProvider] GET query FAILED: $e');
          debugPrint('[AttendanceProvider] Error type: ${e.runtimeType}');
          _error = 'Failed to load daily attendance.';
          notifyListeners();
        });
  }

  /// Load report data (admin)
  Future<void> loadReportData({
    required String startDate,
    required String endDate,
    String? uid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reportData = await _firestoreService.getAttendanceReport(
        startDate: startDate,
        endDate: endDate,
        uid: uid,
      );
    } catch (e) {
      _error = 'Failed to load report data.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _dailySubscription?.cancel();
    super.dispose();
  }
}
