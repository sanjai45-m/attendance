import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService _instance =
      LocalNotificationService._();
  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  int _notificationId = 0;

  /// Initialize the local notifications plugin
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(initSettings);

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'attendance_notifications',
      'Attendance Notifications',
      description: 'Notifications for punch in/out and leave updates',
      importance: Importance.high,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show a local notification (used for foreground FCM messages)
  Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_notifications',
      'Attendance Notifications',
      channelDescription: 'Notifications for punch in/out and leave updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      _notificationId++,
      title,
      body,
      details,
    );
  }
}
