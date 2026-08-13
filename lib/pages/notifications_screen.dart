import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<NotificationItem>> _notifFuture;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';

  static const _typeIcons = {
    'announcement.published': Icons.campaign_rounded,
    'policy.published': Icons.menu_book_rounded,
    'document.uploaded': Icons.description_rounded,
  };

  static const _typeColors = {
    'announcement.published': AppColors.primary,
    'policy.published': Color(0xFF9333EA),
    'document.uploaded': AppColors.primary,
  };

  static const _typeBgs = {
    'announcement.published': AppColors.primaryLight,
    'policy.published': Color(0xFFF3E8FF),
    'document.uploaded': AppColors.primaryLight,
  };

  @override
  void initState() {
    super.initState();
    _notifFuture = NotificationsRepository().getAdminAll();
  }

  void _refresh() {
    setState(() {
      _notifFuture = NotificationsRepository().getAdminAll(
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
        status: _statusFilter,
      );
    });
  }

  Future<void> _markRead(int id) async {
    try {
      await NotificationsRepository().adminMarkRead(id);
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
      await NotificationsRepository().adminMarkAllRead();
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.allMarkedRead),
            backgroundColor: AppColors.success,
          ),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(l10n.readAll),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Status filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() => _searchTerm = val.toLowerCase());
                    },
                    onSubmitted: (_) => _refresh(),
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.grey400,
                        size: 20,
                      ),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.grey400,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchTerm = '');
                                _refresh();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey200),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceLight,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'unread',
                          child: Text('Unread', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'read',
                          child: Text('Read', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _statusFilter = v);
                          _refresh();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: FutureBuilder<List<NotificationItem>>(
              future: _notifFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingIndicator(message: l10n.loadingNotifications);
                }
                if (snapshot.hasError) {
                  return Center(
                    child: OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noNotifications,
                      style: const TextStyle(color: AppColors.grey400),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    final isUnread = !n.isRead;
                    final typeIcon =
                        _typeIcons[n.type] ?? Icons.notifications_outlined;
                    final typeColor =
                        _typeColors[n.type] ??
                        (isUnread ? AppColors.warning : AppColors.grey500);
                    final typeBg =
                        _typeBgs[n.type] ??
                        (isUnread ? AppColors.warningLight : AppColors.grey100);
                    return InkWell(
                      onTap: () => _openDetails(n),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUnread
                              ? AppColors.warningLight
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey900.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isUnread
                                ? AppColors.warning
                                : AppColors.grey200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: typeBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnread
                                      ? AppColors.warning
                                      : AppColors.grey200,
                                ),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 15,
                                      color: isUnread
                                          ? AppColors.grey900
                                          : AppColors.grey600,
                                    ),
                                  ),
                                  if (n.body != null && n.body!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isUnread
                                            ? AppColors.grey600
                                            : AppColors.grey400,
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
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        formatDateTime(n.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread)
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
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
          ),
        ],
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
