import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/screens/auth/login_screen.dart';
import 'package:attendance/screens/admin/admin_dashboard_screen.dart';
import 'package:attendance/screens/admin/create_employee_screen.dart';
import 'package:attendance/screens/admin/employee_list_screen.dart';
import 'package:attendance/screens/admin/edit_employee_screen.dart';
import 'package:attendance/screens/admin/attendance_dashboard_screen.dart';
import 'package:attendance/screens/admin/reports_screen.dart';
import 'package:attendance/screens/admin/overtime_report_screen.dart';
import 'package:attendance/screens/admin/admin_leave_requests_screen.dart';
import 'package:attendance/screens/admin/admin_notifications_screen.dart';
import 'package:attendance/screens/employee/employee_dashboard_screen.dart';
import 'package:attendance/screens/employee/punch_screen.dart';
import 'package:attendance/screens/employee/attendance_history_screen.dart';
import 'package:attendance/screens/employee/apply_leave_screen.dart';
import 'package:attendance/screens/employee/employee_notifications_screen.dart';
import 'package:attendance/screens/admin/settings_screen.dart';
import 'package:attendance/core/constants/app_colors.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isInitialized = authProvider.isInitialized;
        final isLoggedIn = authProvider.isLoggedIn;
        final currentLocation = state.matchedLocation;

        // Still loading auth state — stay on splash
        if (!isInitialized) {
          return currentLocation == '/splash' ? null : '/splash';
        }

        // Auth loaded, but not logged in — go to login
        if (!isLoggedIn) {
          return currentLocation == '/login' ? null : '/login';
        }

        // Logged in — redirect away from splash/login
        if (currentLocation == '/splash' || currentLocation == '/login') {
          return authProvider.isAdmin ? '/admin' : '/employee';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        // ─── Admin Routes ────────────────────────────────
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
          routes: [
            GoRoute(
              path: 'employees',
              builder: (context, state) => const EmployeeListScreen(),
            ),
            GoRoute(
              path: 'create-employee',
              builder: (context, state) => const CreateEmployeeScreen(),
            ),
            GoRoute(
              path: 'edit-employee/:uid',
              builder: (context, state) =>
                  EditEmployeeScreen(uid: state.pathParameters['uid']!),
            ),
            GoRoute(
              path: 'attendance',
              builder: (context, state) => const AttendanceDashboardScreen(),
            ),
            GoRoute(
              path: 'reports',
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: 'overtime-reports',
              builder: (context, state) => const OvertimeReportScreen(),
            ),
            GoRoute(
              path: 'leave-requests',
              builder: (context, state) => const AdminLeaveRequestsScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const AdminNotificationsScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),

        // ─── Employee Routes ─────────────────────────────
        GoRoute(
          path: '/employee',
          builder: (context, state) => const EmployeeDashboardScreen(),
          routes: [
            GoRoute(
              path: 'punch',
              builder: (context, state) => const PunchScreen(),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => const AttendanceHistoryScreen(),
            ),
            GoRoute(
              path: 'apply-leave',
              builder: (context, state) => const ApplyLeaveScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const EmployeeNotificationsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Simple splash screen shown while checking auth state
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
