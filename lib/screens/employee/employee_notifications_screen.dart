import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/auth_provider.dart';
import 'package:attendance/providers/notification_provider.dart';

class EmployeeNotificationsScreen extends StatefulWidget {
  const EmployeeNotificationsScreen({super.key});

  @override
  State<EmployeeNotificationsScreen> createState() =>
      _EmployeeNotificationsScreenState();
}

class _EmployeeNotificationsScreenState
    extends State<EmployeeNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.uid != null) {
        context.read<NotificationProvider>().startStreaming(auth.uid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProv = context.watch<NotificationProvider>();
    final notifications = notificationProv.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: () {
                notificationProv.markAllAsRead();
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Stack(
                  children: [
                    Card(
                      color: notif.isRead
                          ? AppColors.cardBg
                          : AppColors.surfaceBg,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: notif.isRead
                              ? AppColors.divider
                              : AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: notif.isRead
                              ? AppColors.surfaceBg
                              : AppColors.primary.withValues(alpha: 0.2),
                          child: Icon(
                            notif.type == 'LeaveResult'
                                ? Icons.verified_rounded
                                : Icons.notifications_rounded,
                            color: notif.isRead
                                ? AppColors.textMuted
                                : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: notif.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: TextStyle(
                                color: notif.isRead
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary.withValues(
                                        alpha: 0.9,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppDateUtils.toDisplayDate(notif.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!notif.isRead) {
                            notificationProv.markAsRead(notif.id!);
                          }
                        },
                      ),
                    ),
                    if (!notif.isRead)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
