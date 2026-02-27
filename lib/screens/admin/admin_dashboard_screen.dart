import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/providers/notification_provider.dart';
import 'package:attendance/widgets/app_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadEmployees();
      context.read<AttendanceProvider>().loadDailyAttendance(
        AppDateUtils.todayString(),
      );
      context.read<NotificationProvider>().startStreaming('admin');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final authProvider = context.watch<AuthProvider>();

    final totalEmployees = userProvider.employees.length;
    final todayRecords = attendanceProvider.dailyAttendance;
    final presentCount = todayRecords
        .where((a) => a.status.toJson() == 'present')
        .length;
    final lateCount = todayRecords
        .where((a) => a.status.toJson() == 'late')
        .length;
    final absentCount = totalEmployees - presentCount - lateCount;

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
            onPressed: () => context.go('/admin/notifications'),
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
              'Welcome, ${authProvider.currentUser?.name ?? 'Admin'} 👋',
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

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.people_rounded,
                    label: 'Total',
                    value: '$totalEmployees',
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.check_circle_outline,
                    label: 'Present',
                    value: '$presentCount',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.schedule_rounded,
                    label: 'Late',
                    value: '$lateCount',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.cancel_outlined,
                    label: 'Absent',
                    value: '${absentCount < 0 ? 0 : absentCount}',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _actionTile(
              context,
              icon: Icons.person_add_rounded,
              label: 'Create Employee',
              subtitle: 'Add a new team member',
              route: '/admin/create-employee',
            ),
            _actionTile(
              context,
              icon: Icons.people_rounded,
              label: 'View Employees',
              subtitle: 'Manage your team',
              route: '/admin/employees',
            ),
            _actionTile(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Attendance Board',
              subtitle: 'Today\'s attendance overview',
              route: '/admin/attendance',
            ),
            _actionTile(
              context,
              icon: Icons.description_rounded,
              label: 'Reports',
              subtitle: 'Export attendance data',
              route: '/admin/reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
