import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

enum NotificationTimelineGroup {
  today,
  yesterday,
  thisWeek,
  earlier,
}

class NotificationTypeConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;

  const NotificationTypeConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
  });
}

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
  String _filterKey = 'all';
  bool _isSearchVisible = false;
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
      );
    }
    return repo.getAll(
      search: _searchTerm.isNotEmpty ? _searchTerm : null,
    );
  }

  void _refresh() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifFuture = _fetchNotifications();
    });
    ref.invalidate(unreadCountProvider);
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
    HapticFeedback.mediumImpact();
    try {
      final repo = NotificationsRepository();
      if (_isAdmin) {
        await repo.adminMarkAllRead();
      } else {
        await repo.markAllRead();
      }
      _refresh();
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.allMarkedRead,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  NotificationTypeConfig _getTypeConfig(
    String type,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final t = type.toLowerCase();
    if (t.contains('announcement')) {
      return NotificationTypeConfig(
        icon: Icons.campaign_rounded,
        color: const Color(0xFFE11D48),
        bgColor: isDark ? const Color(0xFF3B1219) : const Color(0xFFFFE4E6),
        label: l10n.filterAnnouncements,
      );
    }
    if (t.contains('policy')) {
      return NotificationTypeConfig(
        icon: Icons.policy_rounded,
        color: const Color(0xFFDB2777),
        bgColor: isDark ? const Color(0xFF381324) : const Color(0xFFFCE7F3),
        label: l10n.filterPolicies,
      );
    }
    if (t.contains('document')) {
      return NotificationTypeConfig(
        icon: Icons.description_rounded,
        color: const Color(0xFF0D9488),
        bgColor: isDark ? const Color(0xFF0F2E2B) : const Color(0xFFCCFBF1),
        label: l10n.documents,
      );
    }
    if (t.contains('leave')) {
      return NotificationTypeConfig(
        icon: Icons.event_available_rounded,
        color: const Color(0xFF0284C7),
        bgColor: isDark ? const Color(0xFF0C2A42) : const Color(0xFFE0F2FE),
        label: l10n.navLeave,
      );
    }
    if (t.contains('attendance') ||
        t.contains('correction') ||
        t.contains('clock')) {
      return NotificationTypeConfig(
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFF4F46E5),
        bgColor: isDark ? const Color(0xFF1E1E4B) : const Color(0xFFEEF2FF),
        label: l10n.filterAttendance,
      );
    }
    if (t.contains('overtime')) {
      return NotificationTypeConfig(
        icon: Icons.schedule_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF2B1647) : const Color(0xFFF3E8FF),
        label: l10n.overtime,
      );
    }
    if (t.contains('expense')) {
      return NotificationTypeConfig(
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF3D2506) : const Color(0xFFFEF3C7),
        label: l10n.expenses,
      );
    }
    if (t.contains('payroll') ||
        t.contains('salary') ||
        t.contains('payslip')) {
      return NotificationTypeConfig(
        icon: Icons.payments_rounded,
        color: const Color(0xFF059669),
        bgColor: isDark ? const Color(0xFF063323) : const Color(0xFFD1FAE5),
        label: l10n.payroll,
      );
    }
    return NotificationTypeConfig(
      icon: Icons.notifications_rounded,
      color: AppColors.primary,
      bgColor: isDark ? const Color(0xFF0E2248) : const Color(0xFFDBEAFE),
      label: l10n.notifications,
    );
  }

  String _formatNotificationTime(String dateStr, AppLocalizations l10n) {
    if (dateStr.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inSeconds < 60 && difference.inSeconds >= 0) {
        return l10n.timelineToday;
      } else if (difference.inMinutes < 60 && difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24 &&
          dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year) {
        return '${difference.inHours}h ago · ${DateFormat('hh:mm a').format(dt)}';
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        if (dt.day == yesterday.day &&
            dt.month == yesterday.month &&
            dt.year == yesterday.year) {
          return '${l10n.timelineYesterday} · ${DateFormat('hh:mm a').format(dt)}';
        } else if (dt.year == now.year) {
          return DateFormat('MMM d · hh:mm a').format(dt);
        } else {
          return DateFormat('MMM d, yyyy · hh:mm a').format(dt);
        }
      }
    } catch (_) {
      return dateStr;
    }
  }

  NotificationTimelineGroup _getTimelineGroup(DateTime dt, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final thisWeekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    if (dt.isAfter(todayStart) || dt.isAtSameMomentAs(todayStart)) {
      return NotificationTimelineGroup.today;
    } else if (dt.isAfter(yesterdayStart)) {
      return NotificationTimelineGroup.yesterday;
    } else if (dt.isAfter(thisWeekStart)) {
      return NotificationTimelineGroup.thisWeek;
    } else {
      return NotificationTimelineGroup.earlier;
    }
  }

  String _getTimelineGroupTitle(
    NotificationTimelineGroup group,
    AppLocalizations l10n,
  ) {
    switch (group) {
      case NotificationTimelineGroup.today:
        return l10n.timelineToday;
      case NotificationTimelineGroup.yesterday:
        return l10n.timelineYesterday;
      case NotificationTimelineGroup.thisWeek:
        return l10n.timelineThisWeek;
      case NotificationTimelineGroup.earlier:
        return l10n.timelineEarlier;
    }
  }

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    var list = items;

    // 1. Search term filter
    if (_searchTerm.isNotEmpty) {
      list = list.where((n) {
        final titleMatch = n.title.toLowerCase().contains(_searchTerm);
        final bodyMatch = (n.body ?? '').toLowerCase().contains(_searchTerm);
        final typeMatch = n.type.toLowerCase().contains(_searchTerm);
        return titleMatch || bodyMatch || typeMatch;
      }).toList();
    }

    // 2. Category / Status filter
    switch (_filterKey) {
      case 'unread':
        list = list.where((n) => !n.isRead).toList();
        break;
      case 'read':
        list = list.where((n) => n.isRead).toList();
        break;
      case 'attendance':
        list = list.where((n) {
          final t = n.type.toLowerCase();
          return t.contains('attendance') ||
              t.contains('correction') ||
              t.contains('clock');
        }).toList();
        break;
      case 'announcements':
        list = list
            .where((n) => n.type.toLowerCase().contains('announcement'))
            .toList();
        break;
      case 'policies':
        list = list
            .where((n) =>
                n.type.toLowerCase().contains('policy') ||
                n.type.toLowerCase().contains('document'))
            .toList();
        break;
      case 'requests':
        list = list.where((n) {
          final t = n.type.toLowerCase();
          return t.contains('leave') ||
              t.contains('overtime') ||
              t.contains('expense') ||
              t.contains('payroll') ||
              t.contains('salary');
        }).toList();
        break;
      case 'all':
      default:
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        body: FutureBuilder<List<NotificationItem>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            final rawItems = snapshot.data ?? [];
            final unreadCount = rawItems.where((n) => !n.isRead).length;
            final waiting =
                snapshot.connectionState == ConnectionState.waiting;

            return SafeArea(
              child: Column(
                children: [
                  // ── Clean Native-style App Header ──
                  _buildHeader(
                    context: context,
                    l10n: l10n,
                    isDark: isDark,
                    unreadCount: unreadCount,
                  ),

                  // ── Collapsible Search Bar ──
                  if (_isSearchVisible)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onChanged: (val) => setState(
                            () => _searchTerm = val.toLowerCase().trim(),
                          ),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.searchNotificationsHint,
                            hintStyle: const TextStyle(
                              color: AppColors.grey400,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.grey400,
                              size: 18,
                            ),
                            suffixIcon: _searchTerm.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 16,
                                      color: AppColors.grey400,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchTerm = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),

                  // ── Refined Filter Pills Bar ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: l10n.filterAll,
                            value: 'all',
                            count: rawItems.length,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: l10n.filterUnread,
                            value: 'unread',
                            count: unreadCount,
                            isHighlightedBadge: unreadCount > 0,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: l10n.filterAttendance,
                            value: 'attendance',
                            icon: Icons.fingerprint_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: l10n.filterAnnouncements,
                            value: 'announcements',
                            icon: Icons.campaign_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: l10n.filterRequests,
                            value: 'requests',
                            icon: Icons.assignment_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildFilterChip(
                            label: l10n.filterPolicies,
                            value: 'policies',
                            icon: Icons.policy_rounded,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Feed Body ──
                  Expanded(
                    child: waiting
                        ? LoadingIndicator(message: l10n.loadingNotifications)
                        : snapshot.hasError
                            ? _buildErrorState(isDark, l10n)
                            : _buildFeed(context, rawItems, isDark, l10n),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header (matches dashboard heading language) ──
  Widget _buildHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isDark,
    required int unreadCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (context.canPop()) ...[
            _iconAction(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
              isDark: isDark,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.notifications,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount ${l10n.filterUnread.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _iconAction(
            icon: _isSearchVisible
                ? Icons.search_off_rounded
                : Icons.search_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchCtrl.clear();
                  _searchTerm = '';
                }
              });
            },
            isDark: isDark,
            isActive: _isSearchVisible,
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            _iconAction(
              icon: Icons.done_all_rounded,
              onTap: _markAllRead,
              isDark: isDark,
              tint: AppColors.primary,
            ),
          ],
          const SizedBox(width: 8),
          _iconAction(
            icon: Icons.refresh_rounded,
            onTap: _refresh,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
    Color? tint,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark ? AppColors.surfaceDarkElevated : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: isActive
              ? AppColors.primary
              : (tint ?? (isDark ? AppColors.grey300 : AppColors.grey700)),
        ),
      ),
    );
  }

  // ── Feed Builder ──
  Widget _buildFeed(
    BuildContext context,
    List<NotificationItem> rawItems,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final filteredItems = _applyFilter(rawItems);
    if (filteredItems.isEmpty) {
      return _buildEmptyState(rawItems.isEmpty, isDark, l10n);
    }

    final now = DateTime.now();
    final grouped = <NotificationTimelineGroup, List<NotificationItem>>{};
    for (final item in filteredItems) {
      DateTime itemDate;
      try {
        itemDate = DateTime.parse(item.createdAt).toLocal();
      } catch (_) {
        itemDate = now;
      }
      grouped.putIfAbsent(_getTimelineGroup(itemDate, now), () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: grouped.length,
        itemBuilder: (context, groupIndex) {
          final group = grouped.keys.elementAt(groupIndex);
          final groupItems = grouped[group]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section heading (dashboard style: accent bar + title) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _getTimelineGroupTitle(group, l10n),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${groupItems.length}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),

              // ── One surface per group, hairline dividers between rows ──
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.20 : 0.02,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < groupItems.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 62,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      _buildNotificationCard(groupItems[i], isDark, l10n),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Notification Row ──
  Widget _buildNotificationCard(
    NotificationItem n,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isUnread = !n.isRead;
    final config = _getTypeConfig(n.type, l10n, isDark);
    final relativeTime = _formatNotificationTime(n.createdAt, l10n);

    return Dismissible(
      key: ValueKey('notif_${n.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: isUnread ? const Color(0xFF10B981) : const Color(0xFF6366F1),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              isUnread
                  ? Icons.done_all_rounded
                  : Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isUnread ? l10n.markAsRead : l10n.markAsUnread,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (isUnread) {
          await _markRead(n.id);
        }
        return false;
      },
      child: Material(
        color: isUnread
            ? AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.035)
            : Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(n),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category icon ──
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: config.bgColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(config.icon, color: config.color, size: 18),
                ),
                const SizedBox(width: 12),

                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                                height: 1.25,
                                letterSpacing: -0.2,
                                color:
                                    isDark ? Colors.white : AppColors.grey900,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (n.body != null && n.body!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          n.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color:
                                isDark ? AppColors.grey400 : AppColors.grey600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        '${config.label}  ·  $relativeTime',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.grey500 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Clean Filter Chip ──
  Widget _buildFilterChip({
    required String label,
    required String value,
    int? count,
    IconData? icon,
    bool isHighlightedBadge = false,
    required bool isDark,
  }) {
    final isSelected = _filterKey == value;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterKey = value);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.grey400 : AppColors.grey600),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(60)
                      : (isHighlightedBadge
                          ? AppColors.primary.withAlpha(isDark ? 60 : 30)
                          : (isDark
                              ? Colors.white.withAlpha(20)
                              : Colors.black.withAlpha(15))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isHighlightedBadge
                            ? (isDark
                                ? const Color(0xFF93C5FD)
                                : AppColors.primary)
                            : (isDark
                                ? AppColors.grey300
                                : AppColors.grey700)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(
    bool isCompletelyEmpty,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDarkElevated
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filterKey == 'unread'
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_none_rounded,
                size: 26,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isCompletelyEmpty
                  ? l10n.noNotifications
                  : (_searchTerm.isNotEmpty
                      ? l10n.noMatchingNotifications
                      : (_filterKey == 'unread'
                          ? l10n.allCaughtUp
                          : l10n.noFilterNotifications)),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.grey900,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isCompletelyEmpty
                  ? l10n.emptyNotificationsPrompt
                  : (_searchTerm.isNotEmpty
                      ? l10n.searchSuggestions
                      : l10n.checkOtherTabs),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            if (!isCompletelyEmpty &&
                (_searchTerm.isNotEmpty || _filterKey != 'all')) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _searchCtrl.clear();
                  setState(() {
                    _searchTerm = '';
                    _filterKey = 'all';
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : AppColors.grey800,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFCBD5E1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  l10n.clearFilters,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Error State ──
  Widget _buildErrorState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.failedToLoadProfile,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.grey900,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
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
