import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/constants/app_strings.dart';
import 'package:attendance/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isAdmin = authProvider.isAdmin;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Menu Items
          if (isAdmin) ...[
            _menuItem(
              context,
              icon: Icons.dashboard_rounded,
              label: AppStrings.dashboard,
              route: '/admin',
            ),
            _menuItem(
              context,
              icon: Icons.people_rounded,
              label: AppStrings.employees,
              route: '/admin/employees',
            ),
            _menuItem(
              context,
              icon: Icons.person_add_rounded,
              label: AppStrings.createEmployee,
              route: '/admin/create-employee',
            ),
            _menuItem(
              context,
              icon: Icons.calendar_today_rounded,
              label: AppStrings.attendanceDashboard,
              route: '/admin/attendance',
            ),
            _menuItem(
              context,
              icon: Icons.description_rounded,
              label: AppStrings.reports,
              route: '/admin/reports',
            ),
          ] else ...[
            _menuItem(
              context,
              icon: Icons.dashboard_rounded,
              label: AppStrings.dashboard,
              route: '/employee',
            ),
            _menuItem(
              context,
              icon: Icons.fingerprint_rounded,
              label: '${AppStrings.punchIn} / ${AppStrings.punchOut}',
              route: '/employee/punch',
            ),
            _menuItem(
              context,
              icon: Icons.history_rounded,
              label: AppStrings.attendanceHistory,
              route: '/employee/history',
            ),
          ],

          const Spacer(),
          const Divider(),

          // Logout
          _menuItem(
            context,
            icon: Icons.logout_rounded,
            label: AppStrings.logout,
            route: '',
            onTap: () => _showLogoutDialog(context),
            iconColor: AppColors.error,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: iconColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            context.go(route);
          },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close drawer
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
