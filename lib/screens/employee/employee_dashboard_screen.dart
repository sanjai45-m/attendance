import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/providers/settings_provider.dart';
import 'package:attendance/providers/notification_provider.dart';
import 'package:attendance/widgets/app_drawer.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.uid != null) {
        context.read<AttendanceProvider>().loadTodayAttendance(auth.uid!);
        context.read<SettingsProvider>().loadSettings();
        context.read<NotificationProvider>().startStreaming(auth.uid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final today = attendance.todayAttendance;

    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.notifications_rounded),
            ),
            onPressed: () => context.go('/employee/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hello, ${auth.currentUser?.name ?? 'Employee'} 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppDateUtils.toDisplayDate(DateTime.now()),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // Today's status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Today\'s Status',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    today == null
                        ? Icons.remove_circle_outline
                        : today.hasPunchedOut
                        ? Icons.check_circle_rounded
                        : Icons.timelapse_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    today == null
                        ? 'Not Punched In'
                        : today.hasPunchedOut
                        ? 'Day Complete'
                        : 'Working...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (today != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timePill(
                          'IN',
                          today.punchIn != null
                              ? AppDateUtils.toTimeString(today.punchIn!)
                              : '--',
                        ),
                        const SizedBox(width: 16),
                        _timePill(
                          'OUT',
                          today.punchOut != null
                              ? AppDateUtils.toTimeString(today.punchOut!)
                              : '--',
                        ),
                        const SizedBox(width: 16),
                        _timePill('HRS', today.totalHoursFormatted),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions
            _actionTile(
              context,
              icon: Icons.fingerprint_rounded,
              label: '${AppStrings.punchIn} / ${AppStrings.punchOut}',
              subtitle: 'Record your attendance',
              route: '/employee/punch',
            ),
            _actionTile(
              context,
              icon: Icons.history_rounded,
              label: AppStrings.attendanceHistory,
              subtitle: 'View your past records',
              route: '/employee/history',
            ),
            _actionTile(
              context,
              icon: Icons.event_available_rounded,
              label: 'Apply for Leave',
              subtitle: 'Request time off or sick leave',
              route: '/employee/apply-leave',
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
        onTap: () => context.go(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
