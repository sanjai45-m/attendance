import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/widgets/attendance_card.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.todayString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadDailyAttendance(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final records = attendanceProvider.dailyAttendance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.attendanceDashboard),
      ),
      body: Column(
        children: [
          // Date picker bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.cardBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => _changeDate(-1),
                ),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppDateUtils.toDisplayDate(
                              AppDateUtils.parseDate(_selectedDate)),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textPrimary),
                  onPressed: _selectedDate != AppDateUtils.todayString()
                      ? () => _changeDate(1)
                      : null,
                ),
              ],
            ),
          ),

          // Summary strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _miniStat(
                    'Present',
                    records
                        .where((a) => a.status.toJson() == 'present')
                        .length,
                    AppColors.success),
                const SizedBox(width: 16),
                _miniStat(
                    'Late',
                    records
                        .where((a) => a.status.toJson() == 'late')
                        .length,
                    AppColors.warning),
                const SizedBox(width: 16),
                _miniStat('Total', records.length, AppColors.info),
              ],
            ),
          ),

          const Divider(height: 1),

          // Records
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 56,
                            color:
                                AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        const Text(
                          'No attendance records',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      return AttendanceCard(
                        attendance: records[index],
                        showEmployeeName: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _changeDate(int days) {
    final current = AppDateUtils.parseDate(_selectedDate);
    final newDate = current.add(Duration(days: days));
    final today = DateTime.now();

    if (newDate.isAfter(today)) return;

    setState(() {
      _selectedDate = AppDateUtils.toDateString(newDate);
    });
    context.read<AttendanceProvider>().loadDailyAttendance(_selectedDate);
  }

  Future<void> _pickDate(BuildContext context) async {
    final attendanceProv = context.read<AttendanceProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.parseDate(_selectedDate),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = AppDateUtils.toDateString(picked);
      });
      attendanceProv.loadDailyAttendance(_selectedDate);
    }
  }
}
