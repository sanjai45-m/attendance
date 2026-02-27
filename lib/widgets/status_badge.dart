import 'package:flutter/material.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/enums/attendance_status.dart';

class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case AttendanceStatus.present:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        break;
      case AttendanceStatus.late_:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        break;
      case AttendanceStatus.absent:
        bgColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        break;
      case AttendanceStatus.onLeave:
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
