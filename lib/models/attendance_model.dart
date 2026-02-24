import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/core/enums/attendance_status.dart';

class AttendanceModel {
  final String? id;
  final String uid;
  final String employeeId;
  final String employeeName;
  final String date;
  final DateTime? punchIn;
  final DateTime? punchOut;
  final double? totalHours;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    this.id,
    required this.uid,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    this.punchIn,
    this.punchOut,
    this.totalHours,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceModel(
      id: docId,
      uid: map['uid'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      date: map['date'] ?? '',
      punchIn: (map['punchIn'] as Timestamp?)?.toDate(),
      punchOut: (map['punchOut'] as Timestamp?)?.toDate(),
      totalHours: (map['totalHours'] as num?)?.toDouble(),
      status: AttendanceStatus.fromString(map['status'] ?? 'absent'),
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
      'punchIn': punchIn != null ? Timestamp.fromDate(punchIn!) : null,
      'punchOut': punchOut != null ? Timestamp.fromDate(punchOut!) : null,
      'totalHours': totalHours,
      'status': status.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? uid,
    String? employeeId,
    String? employeeName,
    String? date,
    DateTime? punchIn,
    DateTime? punchOut,
    double? totalHours,
    AttendanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      date: date ?? this.date,
      punchIn: punchIn ?? this.punchIn,
      punchOut: punchOut ?? this.punchOut,
      totalHours: totalHours ?? this.totalHours,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasPunchedIn => punchIn != null;
  bool get hasPunchedOut => punchOut != null;
  bool get isComplete => hasPunchedIn && hasPunchedOut;

  String get totalHoursFormatted {
    if (totalHours == null) return '--';
    final hours = totalHours!.floor();
    final minutes = ((totalHours! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}
