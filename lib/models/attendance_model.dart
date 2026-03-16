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
  final String? punchInLocation;
  final String? punchOutLocation;
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
    this.punchInLocation,
    this.punchOutLocation,
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
      punchInLocation: map['punchInLocation']?.toString(),
      punchOutLocation: map['punchOutLocation']?.toString(),
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
      'punchInLocation': punchInLocation,
      'punchOutLocation': punchOutLocation,
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
    String? punchInLocation,
    String? punchOutLocation,
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
      punchInLocation: punchInLocation ?? this.punchInLocation,
      punchOutLocation: punchOutLocation ?? this.punchOutLocation,
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

  double getOvertimeHours(String workEndTime) {
    if (punchOut == null) return 0.0;

    // Parse the configured end time
    final parts = workEndTime.split(':');
    if (parts.length < 2) return 0.0;

    final endHour = int.tryParse(parts[0]) ?? 18;
    final endMinute = int.tryParse(parts[1]) ?? 0;

    // Create a DateTime representing the threshold for this punchOut day
    final threshold = DateTime(
      punchOut!.year,
      punchOut!.month,
      punchOut!.day,
      endHour,
      endMinute,
    );

    if (punchOut!.isAfter(threshold)) {
      return punchOut!.difference(threshold).inMinutes / 60.0;
    }
    return 0.0;
  }

  String formatOvertimeHours(String workEndTime) {
    final ot = getOvertimeHours(workEndTime);
    if (ot <= 0.01) return '';

    final hours = ot.floor();
    final minutes = ((ot - hours) * 60).round();
    return '${hours}h ${minutes}m OT';
  }
}
