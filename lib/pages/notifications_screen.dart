import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<NotificationItem>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _notifFuture = NotificationsRepository().getAll();
  }

  void _refresh() {
    setState(() {
      _notifFuture = NotificationsRepository().getAll();
    });
  }

  Future<void> _markRead(int id) async {
    try {
      await NotificationsRepository().markRead(id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationsRepository().markAllRead();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All marked read'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Read All'),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notifFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading notifications...');
          }
          if (snapshot.hasError) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications', style: TextStyle(color: AppColors.grey400)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              final isUnread = !n.isRead;
              return InkWell(
                onTap: isUnread ? () => _markRead(n.id) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUnread ? AppColors.primaryLight : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnread ? AppColors.primary.withAlpha(50) : AppColors.grey200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isUnread
                              ? AppColors.primary.withAlpha(20)
                              : AppColors.grey200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isUnread ? Icons.notifications_active : Icons.notifications_outlined,
                          color: isUnread ? AppColors.primary : AppColors.grey500,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 15,
                                color: isUnread ? Colors.black87 : AppColors.grey600,
                              ),
                            ),
                            if (n.body != null && n.body!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.body!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUnread ? AppColors.grey600 : AppColors.grey400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  n.createdAt,
                                  style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isUnread)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, size: 20, color: AppColors.primary),
                          onPressed: () => _markRead(n.id),
                          tooltip: 'Mark read',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}