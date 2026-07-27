import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
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
                onTap: () => _openDetails(n),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnread ? const Color(0xFFFFF7ED) : Colors.white, // orange-50 or white
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(
                      color: isUnread ? const Color(0xFFFED7AA) : AppColors.grey200, // orange-200 or grey
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isUnread ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9), // orange-100 or grey-100
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isUnread ? const Color(0xFFFED7AA) : AppColors.grey200)
                        ),
                        child: Icon(
                          isUnread ? Icons.notifications_active : Icons.notifications_outlined,
                          color: isUnread ? const Color(0xFFF97316) : AppColors.grey500, // orange-500
                          size: 24,
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
                            const SizedBox(height: 6),
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
                                  formatDateTime(n.createdAt),
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

  void _openDetails(NotificationItem n) {
    if (!n.isRead) {
      _markRead(n.id);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    n.type.replaceAll('.', ' ').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              n.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatDateTime(n.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.grey200),
            const SizedBox(height: 16),
            Text(
              n.body ?? 'No additional details provided.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}