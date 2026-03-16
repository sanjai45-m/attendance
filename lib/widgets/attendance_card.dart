import 'package:flutter/material.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/models/attendance_model.dart';
import 'package:attendance/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:attendance/widgets/status_badge.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final bool showEmployeeName;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.showEmployeeName = false,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();
    final overtimeText = attendance.formatOvertimeHours(
      settingsProv.settings.workEndTime,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showEmployeeName)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          attendance.employeeId,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      attendance.date,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      if (overtimeText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            overtimeText,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      StatusBadge(status: attendance.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Time row — responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _timeBlock(
                        icon: Icons.login_rounded,
                        label: 'Punch In',
                        time: attendance.punchIn != null
                            ? AppDateUtils.toTimeString(attendance.punchIn!)
                            : '--:--',
                        location: attendance.punchInLocation,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _timeBlock(
                        icon: Icons.logout_rounded,
                        label: 'Punch Out',
                        time: attendance.punchOut != null
                            ? AppDateUtils.toTimeString(attendance.punchOut!)
                            : '--:--',
                        location: attendance.punchOutLocation,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total hours
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            attendance.totalHoursFormatted,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBlock({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
    String? location,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (location != null && location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
