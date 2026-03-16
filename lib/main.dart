import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/providers/attendance_provider.dart';
import 'package:attendance/providers/settings_provider.dart';
import 'package:attendance/providers/leave_provider.dart';
import 'package:attendance/providers/notification_provider.dart';
import 'package:attendance/services/local_notification_service.dart';
import 'package:attendance/services/background_service.dart';
import 'package:attendance/app.dart';

/// Top-level background message handler (must be outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize local notifications for foreground FCM display
  await LocalNotificationService.instance.initialize();

  // Initialize background service (Workmanager)
  await BackgroundService.initialize();

  // Setup FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const App(),
    ),
  );
}
