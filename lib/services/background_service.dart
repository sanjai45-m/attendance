import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:attendance/models/app_settings_model.dart';
import 'package:attendance/core/constants/firestore_paths.dart';
import 'package:attendance/services/local_notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'checkPendingLeavesTask') {
        // Initialize Firebase since this runs in an isolate
        await Firebase.initializeApp();

        // 1. Check settings to see if reminders are enabled
        final firestore = FirebaseFirestore.instance;
        final settingsDoc = await firestore
            .collection(FirestorePaths.settings)
            .doc(FirestorePaths.appSettings)
            .get();

        if (settingsDoc.exists) {
          final settings = AppSettingsModel.fromMap(settingsDoc.data()!);
          if (!settings.enableLeaveReminders) {
            debugPrint('[Workmanager] Leave reminders are disabled in settings.');
            return Future.value(true);
          }
        }

        // 2. Query for pending leaves
        final pendingLeaves = await firestore
            .collection(FirestorePaths.leaveRequests)
            .where('status', isEqualTo: 'Pending')
            .get();

        if (pendingLeaves.docs.isNotEmpty) {
          final count = pendingLeaves.docs.length;
          // 3. Trigger local notification
          await LocalNotificationService.instance.initialize();
          await LocalNotificationService.instance.show(
            title: 'Pending Leave Requests',
            body: 'There are $count pending leave request(s) waiting for approval.',
          );
        }
        
        debugPrint('[Workmanager] Background task completed successfully.');
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('[Workmanager] Background task failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static const String _leaveReminderTask = 'checkPendingLeavesTask';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // shows notification in debug when task runs
    );
  }

  /// Registers a periodic task that runs roughly every 5 hours.
  /// Note: The exact timing is determined by the OS (Android Doze mode, etc.)
  static Future<void> registerLeaveReminderTask() async {
    await Workmanager().registerPeriodicTask(
      'leave_reminder_job',
      _leaveReminderTask,
      frequency: const Duration(hours: 5),
      initialDelay: const Duration(minutes: 15), // Don't run immediately on login
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('[BackgroundService] Leave reminder task registered.');
  }

  static Future<void> cancelLeaveReminderTask() async {
    await Workmanager().cancelByUniqueName('leave_reminder_job');
    debugPrint('[BackgroundService] Leave reminder task cancelled.');
  }
}
