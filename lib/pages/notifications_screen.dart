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
  final List<Color> gradientColors;
  final String label;

  const NotificationTypeConfig({
    required this.icon,
    required this.color,
    required this.gradientColors,
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

  NotificationTypeConfig _getTypeConfig(String type, AppLocalizations l10n) {
    final t = type.toLowerCase();
    if (t.contains('announcement')) {
      return NotificationTypeConfig(
        icon: Icons.campaign_rounded,
        color: const Color(0xFFEF4444),
        gradientColors: [const Color(0xFFFCA5A5), const Color(0xFFEF4444)],
        label: l10n.filterAnnouncements.toUpperCase(),
      );
    }
    if (t.contains('policy')) {
      return NotificationTypeConfig(
        icon: Icons.policy_rounded,
        color: const Color(0xFFEC4899),
        gradientColors: [const Color(0xFFFBCFE8), const Color(0xFFEC4899)],
        label: l10n.filterPolicies.toUpperCase(),
      );
    }
    if (t.contains('document')) {
      return NotificationTypeConfig(
        icon: Icons.description_rounded,
        color: const Color(0xFF14B8A6),
        gradientColors: [const Color(0xFF99F6E4), const Color(0xFF14B8A6)],
        label: l10n.documents.toUpperCase(),
      );
    }
    if (t.contains('leave')) {
      return NotificationTypeConfig(
        icon: Icons.event_available_rounded,
        color: const Color(0xFF0284C7),
        gradientColors: [const Color(0xFFBAE6FD), const Color(0xFF0284C7)],
        label: l10n.navLeave.toUpperCase(),
      );
    }
    if (t.contains('attendance') ||
        t.contains('correction') ||
        t.contains('clock')) {
      return NotificationTypeConfig(
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFF6366F1),
        gradientColors: [const Color(0xFFC7D2FE), const Color(0xFF6366F1)],
        label: l10n.filterAttendance.toUpperCase(),
      );
    }
    if (t.contains('overtime')) {
      return NotificationTypeConfig(
        icon: Icons.schedule_rounded,
        color: const Color(0xFF8B5CF6),
        gradientColors: [const Color(0xFFDDD6FE), const Color(0xFF8B5CF6)],
        label: l10n.overtime.toUpperCase(),
      );
    }
    if (t.contains('expense')) {
      return NotificationTypeConfig(
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFF59E0B),
        gradientColors: [const Color(0xFFFDE68A), const Color(0xFFF59E0B)],
        label: l10n.expenses.toUpperCase(),
      );
    }
    if (t.contains('payroll') ||
        t.contains('salary') ||
        t.contains('payslip')) {
      return NotificationTypeConfig(
        icon: Icons.payments_rounded,
        color: const Color(0xFF10B981),
        gradientColors: [const Color(0xFFA7F3D0), const Color(0xFF10B981)],
        label: l10n.payroll.toUpperCase(),
      );
    }
    return NotificationTypeConfig(
      icon: Icons.notifications_rounded,
      color: AppColors.primary,
      gradientColors: [const Color(0xFF93C5FD), AppColors.primary],
      label: l10n.notifications.toUpperCase(),
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
        return '${difference.inHours}h • ${DateFormat('hh:mm a').format(dt)}';
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        if (dt.day == yesterday.day &&
            dt.month == yesterday.month &&
            dt.year == yesterday.year) {
          return '${l10n.timelineYesterday} • ${DateFormat('hh:mm a').format(dt)}';
        } else if (dt.year == now.year) {
          return DateFormat('dd MMM, hh:mm a').format(dt);
        } else {
          return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF8FAFC),
        body: FutureBuilder<List<NotificationItem>>(
          future: _notifFuture,
          builder: (context, snapshot) {
            final rawItems = snapshot.data ?? [];
            final unreadCount = rawItems.where((n) => !n.isRead).length;
            final waiting =
                snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                // ── Royal Blue Curved Hero Header ──
                _buildRoyalHeroHeader(
                  context: context,
                  l10n: l10n,
                  isDark: isDark,
                  items: rawItems,
                  unreadCount: unreadCount,
                ),

                // ── Filter Chips Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
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
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterUnread,
                          value: 'unread',
                          count: unreadCount,
                          isHighlightedBadge: unreadCount > 0,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterAttendance,
                          value: 'attendance',
                          icon: Icons.fingerprint_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterAnnouncements,
                          value: 'announcements',
                          icon: Icons.campaign_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterPolicies,
                          value: 'policies',
                          icon: Icons.policy_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterRequests,
                          value: 'requests',
                          icon: Icons.assignment_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: l10n.filterRead,
                          value: 'read',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: waiting
                      ? LoadingIndicator(message: l10n.loadingNotifications)
                      : snapshot.hasError
                          ? _buildErrorState(isDark, l10n)
                          : _buildFeed(context, rawItems, isDark, l10n),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Royal Blue Curved Hero Header ──
  Widget _buildRoyalHeroHeader({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool isDark,
    required List<NotificationItem> items,
    required int unreadCount,
  }) {
    final hasUnread = unreadCount > 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8), // Royal Blue Deep
            Color(0xFF0052FF), // Royal Blue Main
            Color(0xFF1E6BFF), // Royal Blue Light Glow
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Navigation Bar ──
                  Row(
                    children: [
                      if (context.canPop()) ...[
                        _frostedHeroButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => context.pop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          l10n.notifications,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _markAllRead,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.done_all_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.readAll,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      _frostedHeroButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onTap: _refresh,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Unread Spotlight Row ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasUnread
                                ? '${l10n.filterUnread.toLowerCase()} · ${items.length} total'
                                : l10n.allCaughtUp,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Frosted Glass Search Field ──
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(
                        () => _searchTerm = val.toLowerCase().trim(),
                      ),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: l10n.searchNotificationsHint,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                        suffixIcon: _searchTerm.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 17,
                                ),
                                color: Colors.white.withValues(alpha: 0.85),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _searchCtrl.clear();
                                  setState(() => _searchTerm = '');
                                },
                              )
                            : null,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frostedHeroButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
        itemCount: grouped.length,
        itemBuilder: (context, groupIndex) {
          final group = grouped.keys.elementAt(groupIndex);
          final groupItems = grouped[group]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
                child: Row(
                  children: [
                    Text(
                      _getTimelineGroupTitle(group, l10n).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDarkElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${groupItems.length}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.grey300
                              : AppColors.grey700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),
              ...groupItems.map((n) => _buildNotificationCard(n, isDark, l10n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.failedToLoadProfile,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.grey900,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification Card with Swipe Gesture & Clean Layout ──
  Widget _buildNotificationCard(
    NotificationItem n,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isUnread = !n.isRead;
    final config = _getTypeConfig(n.type, l10n);
    final relativeTime = _formatNotificationTime(n.createdAt, l10n);

    return Dismissible(
      key: ValueKey('notif_${n.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              isUnread
                  ? Icons.done_all_rounded
                  : Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isUnread ? l10n.markAsRead : l10n.markAsUnread,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF0F6FF))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: isDark ? 0.40 : 0.25)
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: isUnread ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openDetails(n),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Squircle Icon Container with subtle gradient
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                config.color.withValues(alpha: 0.35),
                                config.color.withValues(alpha: 0.18),
                              ]
                            : [
                                config.gradientColors[0]
                                    .withValues(alpha: 0.55),
                                config.gradientColors[1]
                                    .withValues(alpha: 0.25),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: config.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: config.color.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: config.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Title
                        Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 14.5,
                            height: 1.25,
                            color: isDark ? Colors.white : AppColors.grey900,
                            letterSpacing: -0.2,
                          ),
                        ),

                        if (n.body != null && n.body!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            n.body!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Time row
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.grey500
                                  : AppColors.grey400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              relativeTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Unread Dot + Chevron
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isUnread)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 4, bottom: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x660052FF),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Modern Filter Chip ──
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.grey400 : AppColors.grey600),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isHighlightedBadge
                          ? AppColors.primary
                              .withValues(alpha: isDark ? 0.25 : 0.12)
                          : (isDark
                              ? AppColors.grey800
                              : const Color(0xFFE2E8F0))),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _filterKey == 'unread'
                    ? Icons.mark_email_read_rounded
                    : Icons.notifications_none_rounded,
                size: 36,
                color: isDark ? AppColors.grey400 : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
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
                height: 1.4,
              ),
            ),
            if (!isCompletelyEmpty &&
                (_searchTerm.isNotEmpty || _filterKey != 'all')) ...[
              const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.clearFilters,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
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
