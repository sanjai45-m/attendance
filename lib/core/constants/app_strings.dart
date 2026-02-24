class AppStrings {
  AppStrings._();

  static const String appName = 'AttendEase';
  static const String appTagline = 'Smart Attendance Management';

  // Auth
  static const String login = 'Login';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String loginAsAdmin = 'Login as Admin';
  static const String loginAsEmployee = 'Login as Employee';
  static const String forgotPassword = 'Forgot Password?';

  // Admin
  static const String dashboard = 'Dashboard';
  static const String employees = 'Employees';
  static const String createEmployee = 'Create Employee';
  static const String editEmployee = 'Edit Employee';
  static const String attendanceDashboard = 'Attendance';
  static const String reports = 'Reports';
  static const String exportExcel = 'Export Excel';

  // Employee
  static const String punchIn = 'Punch In';
  static const String punchOut = 'Punch Out';
  static const String attendanceHistory = 'Attendance History';

  // Fields
  static const String name = 'Full Name';
  static const String phone = 'Phone Number';
  static const String department = 'Department';
  static const String employeeId = 'Employee ID';
  static const String role = 'Role';

  // Status
  static const String present = 'Present';
  static const String absent = 'Absent';
  static const String late_ = 'Late';

  // Messages
  static const String punchInSuccess = 'Punched In Successfully!';
  static const String punchOutSuccess = 'Punched Out Successfully!';
  static const String alreadyPunchedIn = 'You have already punched in today.';
  static const String noPunchIn = 'You haven\'t punched in yet today.';
  static const String alreadyPunchedOut = 'You have already punched out today.';
  static const String employeeCreated = 'Employee created successfully!';
  static const String employeeUpdated = 'Employee updated successfully!';
  static const String employeeDeleted = 'Employee deleted successfully!';
  static const String reportExported = 'Report exported successfully!';
  static const String logout = 'Logout';
  static const String confirmLogout = 'Are you sure you want to logout?';
}
