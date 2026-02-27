import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String? id;
  final String targetUid; // User UID or 'admin'
  final String title;
  final String message;
  final String type; // e.g. 'LeaveRequest', 'LeaveResult'
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    this.id,
    required this.targetUid,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotificationModel(
      id: docId,
      targetUid: map['targetUid'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetUid': targetUid,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? targetUid,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      targetUid: targetUid ?? this.targetUid,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
