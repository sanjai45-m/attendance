import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:attendance/models/user_model.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/models/app_settings_model.dart';
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
    Query query = _firestore
        .collection(FirestorePaths.attendance)
        .where(FirestorePaths.dateField, isGreaterThanOrEqualTo: startDate)
        .where(FirestorePaths.dateField, isLessThanOrEqualTo: endDate);

    if (uid != null && uid.isNotEmpty) {
      query = query.where(FirestorePaths.uidField, isEqualTo: uid);
    }

    query = query.orderBy(FirestorePaths.dateField, descending: false);

    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
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
}
