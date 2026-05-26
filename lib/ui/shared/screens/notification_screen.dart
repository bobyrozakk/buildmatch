import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../core/utils/formatters.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            child: const Text('Tandai Semua Dibaca', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final notifications = notifProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Tidak ada notifikasi', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => notifProvider.fetchNotifications(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
                IconData icon;
                Color iconColor;
                
                switch(notif.type) {
                  case 'bid':
                    icon = Icons.local_offer_outlined;
                    iconColor = Colors.orange;
                    break;
                  case 'chat':
                    icon = Icons.chat_bubble_outline_rounded;
                    iconColor = AppColors.primary;
                    break;
                  case 'project_update':
                    icon = Icons.check_circle_outline_rounded;
                    iconColor = Colors.green;
                    break;
                  default:
                    icon = Icons.notifications_none_rounded;
                    iconColor = Colors.grey;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  tileColor: notif.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: TextStyle(
                          color: notif.isRead ? Colors.grey : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: const TextStyle(fontSize: 10, color: Colors.black38),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!notif.isRead) {
                      notifProvider.markAsRead(notif.id);
                    }
                    // Implement navigation based on type later if needed
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}
