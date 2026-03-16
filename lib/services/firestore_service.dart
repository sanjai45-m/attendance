import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/models/app_settings_model.dart';
import 'package:attendance/models/leave_request_model.dart';
import 'package:attendance/models/app_notification_model.dart';
import 'package:attendance/core/constants/firestore_paths.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Users ──────────────────────────────────────────────

  /// Stream all employees (for admin)
  Stream<List<UserModel>> streamEmployees() {
    return _firestore
        .collection(FirestorePaths.users)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get single user by UID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Update employee details
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore.collection(FirestorePaths.users).doc(uid).update(data);
  }

  /// Delete employee
  Future<void> deleteUser(String uid) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).delete();
  }

  // ─── Attendance ─────────────────────────────────────────

  /// Get today's attendance record for a user
  Future<AttendanceModel?> getTodayAttendance(String uid, String date) async {
    final query = await _firestore
        .collection(FirestorePaths.attendance)
        .where(FirestorePaths.uidField, isEqualTo: uid)
        .where(FirestorePaths.dateField, isEqualTo: date)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return AttendanceModel.fromMap(
      query.docs.first.data(),
      query.docs.first.id,
    );
  }

  /// Create attendance record (punch in)
  Future<String> createAttendance(AttendanceModel model) async {
    final doc = await _firestore
        .collection(FirestorePaths.attendance)
        .add(model.toMap());
    return doc.id;
  }

  /// Update attendance record (punch out)
  Future<void> updateAttendance(String docId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _firestore
        .collection(FirestorePaths.attendance)
        .doc(docId)
        .update(data);
  }

  /// Stream attendance for a specific date (admin dashboard)
  Stream<List<AttendanceModel>> streamAttendanceByDate(String date) {
    return _firestore
        .collection(FirestorePaths.attendance)
        .where(FirestorePaths.dateField, isEqualTo: date)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort(
            (a, b) =>
                (a.punchIn ?? DateTime(0)).compareTo(b.punchIn ?? DateTime(0)),
          );
          return list;
        });
  }

  /// Stream employee's own attendance history (latest first)
  Stream<List<AttendanceModel>> streamMyAttendance(String uid) {
    return _firestore
        .collection(FirestorePaths.attendance)
        .where(FirestorePaths.uidField, isEqualTo: uid)
        .orderBy(FirestorePaths.dateField, descending: true)
        .limit(30)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Query attendance for report (by date range and optional employee)
  Future<List<AttendanceModel>> getAttendanceReport({
    required String startDate,
    required String endDate,
    String? uid,
  }) async {
    // 1. Only query Firestore based on the Date range
    Query query = _firestore
        .collection(FirestorePaths.attendance)
        .where(FirestorePaths.dateField, isGreaterThanOrEqualTo: startDate)
        .where(FirestorePaths.dateField, isLessThanOrEqualTo: endDate)
        .orderBy(FirestorePaths.dateField, descending: false);

    final snapshot = await query.get();

    // 2. Map docs to models
    var results = snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();

    // 3. Filter by UID locally to bypass the need for a composite index (date + uid)
    if (uid != null && uid.isNotEmpty) {
      results = results.where((e) => e.uid == uid).toList();
    }

    return results;
  }

  // ─── Settings ───────────────────────────────────────────

  /// Get app settings
  Future<AppSettingsModel> getSettings() async {
    final doc = await _firestore
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.appSettings)
        .get();

    if (!doc.exists) return AppSettingsModel();
    final rawData = doc.data()!;
    // Sanitize keys — trim whitespace/tabs that may have been accidentally added
    final data = rawData.map((key, value) => MapEntry(key.trim(), value));
    debugPrint(
      '[FirestoreService] Raw settings keys: ${rawData.keys.map((k) => '"$k"').toList()}',
    );
    debugPrint('[FirestoreService] Sanitized keys: ${data.keys.toList()}');
    return AppSettingsModel.fromMap(data);
  }

  /// Update settings
  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _firestore
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.appSettings)
        .set(data, SetOptions(merge: true));
  }

  /// Stream settings
  Stream<AppSettingsModel> streamSettings() {
    return _firestore
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.appSettings)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return AppSettingsModel();
          return AppSettingsModel.fromMap(doc.data()!);
        });
  }

  // ─── Leave Requests ─────────────────────────────────────

  /// Submit a new leave request
  Future<String> createLeaveRequest(LeaveRequestModel request) async {
    final doc = await _firestore
        .collection(FirestorePaths.leaveRequests)
        .add(request.toMap());
    return doc.id;
  }

  /// Update leave request status (for Admin)
  Future<void> updateLeaveRequestStatus(String docId, String status) async {
    await _firestore.collection(FirestorePaths.leaveRequests).doc(docId).update(
      {'status': status, 'updatedAt': Timestamp.now()},
    );
  }

  /// Stream all leave requests (for Admin)
  Stream<List<LeaveRequestModel>> streamAllLeaveRequests() {
    return _firestore.collection(FirestorePaths.leaveRequests).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => LeaveRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream a specific employee's leave requests
  Stream<List<LeaveRequestModel>> streamMyLeaveRequests(String uid) {
    return _firestore
        .collection(FirestorePaths.leaveRequests)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LeaveRequestModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Check if a non-rejected leave request already exists for a given user and date
  Future<bool> checkExistingLeaveRequest(String uid, String date) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.leaveRequests)
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .get();

    // Return true if any non-rejected request exists
    return snapshot.docs.any((doc) {
      final status = doc.data()['status'] as String? ?? '';
      return status != 'Rejected';
    });
  }

  // ─── Notifications ──────────────────────────────────────

  /// Send a notification
  Future<void> sendNotification(AppNotificationModel notification) async {
    await _firestore
        .collection(FirestorePaths.notifications)
        .add(notification.toMap());
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String docId) async {
    await _firestore.collection(FirestorePaths.notifications).doc(docId).update(
      {'isRead': true},
    );
  }

  /// Mark all notifications as read for a specific user/admin
  Future<void> markAllNotificationsRead(String targetUid) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection(FirestorePaths.notifications)
        .where('targetUid', isEqualTo: targetUid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Stream notifications for a specific user (or 'admin')
  Stream<List<AppNotificationModel>> streamNotifications(String targetUid) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .where('targetUid', isEqualTo: targetUid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
