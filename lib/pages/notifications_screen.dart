import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<NotificationItem>> _notifFuture;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = ref.read(authProvider).isSuperAdmin;
    _notifFuture = _fetchNotifications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<NotificationItem>> _fetchNotifications() {
    final repo = NotificationsRepository();
    if (_isAdmin) {
      return repo.getAdminAll(
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
        status: _statusFilter,
      );
    }
    return repo.getAll(
      search: _searchTerm.isNotEmpty ? _searchTerm : null,
      status: _statusFilter,
    );
  }

  void _refresh() {
    setState(() {
      _notifFuture = _fetchNotifications();
    });
  }

  Future<void> _markRead(int id) async {
    try {
      final repo = NotificationsRepository();
      if (_isAdmin) {
        await repo.adminMarkRead(id);
      } else {
        await repo.markRead(id);
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      final repo = NotificationsRepository();
      if (_isAdmin) {
        await repo.adminMarkAllRead();
      } else {
        await repo.markAllRead();
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.allMarkedRead),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('announcement')) return Icons.campaign_rounded;
    if (type.contains('policy')) return Icons.policy_rounded;
    if (type.contains('document')) return Icons.description_rounded;
    if (type.contains('leave')) return Icons.event_available_rounded;
    if (type.contains('attendance') || type.contains('correction')) return Icons.fingerprint_rounded;
    if (type.contains('overtime')) return Icons.schedule_rounded;
    if (type.contains('expense')) return Icons.receipt_long_rounded;
    if (type.contains('payroll') || type.contains('salary')) return Icons.payments_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getTypeColor(String type) {
    if (type.contains('announcement')) return const Color(0xFFEF4444);
    if (type.contains('policy')) return const Color(0xFFEC4899);
    if (type.contains('document')) return const Color(0xFF14B8A6);
    if (type.contains('leave')) return const Color(0xFF3B82F6);
    if (type.contains('attendance') || type.contains('correction')) return const Color(0xFF6366F1);
    if (type.contains('overtime')) return const Color(0xFF8B5CF6);
    if (type.contains('expense')) return const Color(0xFFF59E0B);
    if (type.contains('payroll') || type.contains('salary')) return const Color(0xFF10B981);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: Text(
              l10n.readAll,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Strip ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() => _searchTerm = val.toLowerCase().trim());
                      _refresh();
                    },
                    style: const TextStyle(fontSize: 13.5, color: AppColors.grey900),
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchTerm = '');
                                _refresh();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Status Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Unread Only', 'unread'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Read', 'read'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Notifications List ──
          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
              future: _notifFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingIndicator(message: l10n.loadingNotifications);
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.grey400),
                        const SizedBox(height: 10),
                        Text(
                          'Failed to load notifications',
                          style: const TextStyle(color: AppColors.grey600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.grey300),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noNotifications,
                          style: const TextStyle(color: AppColors.grey600, fontSize: 14.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final isUnread = !n.isRead;
                      final typeIcon = _getTypeIcon(n.type);
                      final typeColor = _getTypeColor(n.type);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUnread
                                ? typeColor.withValues(alpha: 0.35)
                                : AppColors.grey200.withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUnread
                                  ? typeColor.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _openDetails(n),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(typeIcon, color: typeColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 14,
                                                color: AppColors.grey900,
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(
                                                color: typeColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (n.body != null && n.body!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.grey600,
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formatDateTime(n.createdAt),
                                            style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                                          ),
                                          if (isUnread)
                                            InkWell(
                                              onTap: () => _markRead(n.id),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.check_rounded, size: 13, color: typeColor),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Mark Read',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: typeColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _statusFilter = value);
        _refresh();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEF4444) : AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  void _openDetails(NotificationItem n) {
    if (!n.isRead) {
      _markRead(n.id);
    }
    context.push(
      AppRoutes.notificationDetail.replaceFirst(':id', n.id.toString()),
      extra: n,
    );
  }
}
