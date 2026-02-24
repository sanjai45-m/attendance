class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String users = 'users';
  static const String attendance = 'attendance';
  static const String settings = 'settings';

  // Documents
  static const String appSettings = 'app';

  // User document
  static String userDoc(String uid) => '$users/$uid';

  // Attendance queries
  static const String dateField = 'date';
  static const String uidField = 'uid';
  static const String employeeIdField = 'employeeId';
}
