enum AttendanceStatus {
  present,
  absent,
  late_,
  onLeave; // <-- Added

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late_:
        return 'Late';
      case AttendanceStatus.onLeave:
        return 'On Leave';
    }
  }

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late_;
      case 'on_leave':
        return AttendanceStatus.onLeave;
      default:
        return AttendanceStatus.absent;
    }
  }

  String toJson() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late_:
        return 'late';
      case AttendanceStatus.onLeave:
        return 'on_leave';
    }
  }
}
