import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/core/constants/app_colors.dart';
import 'package:attendance/core/utils/date_utils.dart';
import 'package:attendance/providers/notification_provider.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startStreaming('admin');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProv = context.watch<NotificationProvider>();
    final allNotifications = notificationProv.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notifications'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Leave'),
            Tab(text: 'Attendance'),
          ],
        ),
        actions: [
          if (allNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: () {
                notificationProv.markAllAsRead();
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(allNotifications, 'All', notificationProv),
          _buildNotificationList(
              allNotifications.where((n) => n.type == 'LeaveRequest').toList(),
              'LeaveRequest',
              notificationProv),
          _buildNotificationList(
              allNotifications
                  .where((n) => n.type == 'PunchIn' || n.type == 'PunchOut')
                  .toList(),
              'Attendance',
              notificationProv),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List notifications, String filterType,
      NotificationProvider notificationProv) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          'No notifications in this category.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];

        IconData getIconForType(String type) {
          switch (type) {
            case 'LeaveRequest':
              return Icons.pending_actions_rounded;
            case 'PunchIn':
              return Icons.login_rounded;
            case 'PunchOut':
              return Icons.logout_rounded;
            default:
              return Icons.notifications_rounded;
          }
        }

        return Stack(
          children: [
            Card(
              color: notif.isRead ? AppColors.cardBg : AppColors.surfaceBg,
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
                    getIconForType(notif.type),
                    color:
                        notif.isRead ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight:
                        notif.isRead ? FontWeight.normal : FontWeight.bold,
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
    );
  }
}
