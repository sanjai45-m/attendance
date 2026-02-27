import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestModel {
  final String? id;
  final String uid;
  final String employeeId;
  final String employeeName;
  final String date; // YYYY-MM-DD format
  final String type; // 'Sick' or 'Other'
  final String? reason;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveRequestModel({
    this.id,
    required this.uid,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.type,
    this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return LeaveRequestModel(
      id: docId,
      uid: map['uid'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      type: map['type'] ?? 'Sick',
      reason: map['reason'],
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': date,
      'type': type,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LeaveRequestModel copyWith({
    String? id,
    String? uid,
    String? employeeId,
    String? employeeName,
    String? date,
    String? type,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
