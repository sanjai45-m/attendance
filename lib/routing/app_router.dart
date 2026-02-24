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
import 'package:attendance/screens/employee/employee_dashboard_screen.dart';
import 'package:attendance/screens/employee/punch_screen.dart';
import 'package:attendance/screens/employee/attendance_history_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) {
          return authProvider.isAdmin ? '/admin' : '/employee';
        }
        return null;
      },
      routes: [
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
              builder: (context, state) => EditEmployeeScreen(
                uid: state.pathParameters['uid']!,
              ),
            ),
            GoRoute(
              path: 'attendance',
              builder: (context, state) => const AttendanceDashboardScreen(),
            ),
            GoRoute(
              path: 'reports',
              builder: (context, state) => const ReportsScreen(),
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
          ],
        ),
      ],
    );
  }
}
