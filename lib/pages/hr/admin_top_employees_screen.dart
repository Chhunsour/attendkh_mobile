// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/providers/top_employees_provider.dart';
import 'package:mpg_hr_mobile_app/models/top_employee.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class TopEmployeesScreen extends ConsumerStatefulWidget {
  const TopEmployeesScreen({super.key});

  @override
  ConsumerState<TopEmployeesScreen> createState() => _TopEmployeesScreenState();
}

class _TopEmployeesScreenState extends ConsumerState<TopEmployeesScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _activeCategory = 'attendance';
  String _activeSort = 'by_amount'; // 'by_amount' | 'by_hours'

  static const _categories = [
    {
      'key': 'attendance',
      'icon': Icons.check_circle_outline_rounded,
      'color': Color(0xFF059669),
    },
    {
      'key': 'leave',
      'icon': Icons.calendar_today_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'key': 'check_early',
      'icon': Icons.access_time_filled_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'key': 'check_late',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'key': 'checkout_early',
      'icon': Icons.logout_rounded,
      'color': Color(0xFFEA580C),
    },
    {
      'key': 'checkout_overtime',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF7C3AED),
    },
  ];

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'attendance':
        return l10n.attendanceMenu;
      case 'leave':
        return l10n.leave;
      case 'check_early':
        return l10n.checkEarly;
      case 'check_late':
        return l10n.checkLate;
      case 'checkout_early':
        return l10n.earlyCheckouts;
      case 'checkout_overtime':
        return l10n.overtime;
      default:
        return key;
    }
  }

  String _formatDuration(double hoursDecimal) {
    if (hoursDecimal <= 0) return '0m';
    final h = hoursDecimal.floor();
    final m = ((hoursDecimal - h) * 60).round();
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _getScoreDisplay(TopEmployee emp, AppLocalizations l10n) {
    if (_activeSort == 'by_amount') {
      final unit = _activeCategory == 'leave' ? l10n.days : l10n.times;
      return '${emp.amount} $unit';
    }
    return _formatDuration(emp.hours);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime.now()) || (next.year == DateTime.now().year && next.month == DateTime.now().month)) {
      setState(() {
        _selectedMonth = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final topEmployeesAsync = ref.watch(topEmployeesProvider(monthStr));
    final branchSwitch = ref.watch(branchSwitchProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.topEmployees,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (branchSwitch.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        branchSwitch.activeBranchName ?? '',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(topEmployeesProvider(monthStr));
        },
        child: CustomScrollView(
          slivers: [
            // ── 1. Gold Executive Leaderboard Banner ─────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD97706),
                      Color(0xFFF59E0B),
                      Color(0xFFB45309),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.employeeLeaderboard,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.recognitionRanking,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Month Selector Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _prevMonth,
                          ),
                          InkWell(
                            onTap: () async {
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: _selectedMonth,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedMonth = picked);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 15),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('MMMM yyyy').format(_selectedMonth),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Category Filter Chips ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories Scroll
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _activeCategory == cat['key'];
                          final catColor = cat['color'] as Color;
                          final catLabel = _getCategoryLabel(cat['key'] as String, l10n);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _activeCategory = cat['key'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? catColor : AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? catColor : AppColors.border(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 14,
                                      color: isSelected ? Colors.white : catColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      catLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sort Metric Toggle (By Count / By Hours)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _activeSort = 'by_amount'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: _activeSort == 'by_amount'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    _activeCategory == 'leave' ? l10n.days : l10n.byFrequency,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _activeSort == 'by_amount' ? FontWeight.bold : FontWeight.w500,
                                      color: _activeSort == 'by_amount' ? Colors.white : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _activeSort = 'by_hours'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: _activeSort == 'by_hours'
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.byDuration,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _activeSort == 'by_hours' ? FontWeight.bold : FontWeight.w500,
                                      color: _activeSort == 'by_hours' ? Colors.white : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── 3. Main Data Content ────────────────────────────────────
            topEmployeesAsync.when(
              loading: () => SliverFillRemaining(
                child: Center(
                  child: LoadingIndicator(message: l10n.loadingLeaderboard),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 36),
                      const SizedBox(height: 8),
                      Text('Failed to load: $err', style: const TextStyle(fontSize: 13, color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final currentCategoryData = data[_activeCategory] ?? {'by_amount': [], 'by_hours': []};
                final List<TopEmployee> list = List<TopEmployee>.from(currentCategoryData[_activeSort] ?? []);

                if (list.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: const Icon(Icons.emoji_events_outlined, size: 36, color: AppColors.grey400),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noActivityRecorded,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final top1 = list.isNotEmpty ? list[0] : null;
                final top2 = list.length > 1 ? list[1] : null;
                final top3 = list.length > 2 ? list[2] : null;
                final rest = list.length > 3 ? list.sublist(3) : <TopEmployee>[];

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Podium for Top 3
                      _buildPodium(top1: top1, top2: top2, top3: top3, l10n: l10n),
                      const SizedBox(height: 18),

                      // Leaderboard list for rank 4+
                      if (rest.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            l10n.otherRankings,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary(context),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        ...rest.asMap().entries.map((entry) {
                          final rank = entry.key + 4;
                          final emp = entry.value;
                          return _buildRankCard(rank: rank, emp: emp, l10n: l10n);
                        }),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Podium Widget for Top 3 ────────────────────────────────────────────────
  Widget _buildPodium({
    TopEmployee? top1,
    TopEmployee? top2,
    TopEmployee? top3,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          Expanded(
            child: top2 != null
                ? _buildPodiumColumn(
                    rank: 2,
                    emp: top2,
                    podiumHeight: 90,
                    badgeColor: const Color(0xFF94A3B8),
                    badgeBg: const Color(0xFFF1F5F9),
                    crownIcon: Icons.military_tech_rounded,
                    l10n: l10n,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 1st Place (Gold)
          Expanded(
            child: top1 != null
                ? _buildPodiumColumn(
                    rank: 1,
                    emp: top1,
                    podiumHeight: 120,
                    badgeColor: const Color(0xFFF59E0B),
                    badgeBg: const Color(0xFFFEF3C7),
                    crownIcon: Icons.workspace_premium_rounded,
                    isFirst: true,
                    l10n: l10n,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 3rd Place (Bronze)
          Expanded(
            child: top3 != null
                ? _buildPodiumColumn(
                    rank: 3,
                    emp: top3,
                    podiumHeight: 70,
                    badgeColor: const Color(0xFFD97706),
                    badgeBg: const Color(0xFFFFFBEB),
                    crownIcon: Icons.military_tech_outlined,
                    l10n: l10n,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String? _resolveAvatarUrl(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty) return null;
    final trimmed = avatar.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${DioClient.storageUrl}/$cleanPath';
  }

  Widget _buildAvatarWidget(TopEmployee emp, {required double radius, required Color badgeColor, bool isFirst = false}) {
    final avatarUrl = _resolveAvatarUrl(emp.avatar);
    return CircleAvatar(
      radius: radius,
      backgroundColor: badgeColor.withValues(alpha: 0.18),
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                memCacheWidth: (radius * 4).toInt(),
                memCacheHeight: (radius * 4).toInt(),
                placeholder: (ctx, url) => Center(
                  child: SizedBox(
                    width: radius,
                    height: radius,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: badgeColor,
                    ),
                  ),
                ),
                errorWidget: (ctx, url, err) => Text(
                  emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            )
          : Text(
              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
    );
  }

  Widget _buildPodiumColumn({
    required int rank,
    required TopEmployee emp,
    required double podiumHeight,
    required Color badgeColor,
    required Color badgeBg,
    required IconData crownIcon,
    bool isFirst = false,
    required AppLocalizations l10n,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank Crown / Medal Icon
        Icon(crownIcon, color: badgeColor, size: isFirst ? 26 : 20),
        const SizedBox(height: 4),

        // Avatar
        _buildAvatarWidget(
          emp,
          radius: isFirst ? 28 : 22,
          badgeColor: badgeColor,
          isFirst: isFirst,
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          emp.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isFirst ? 13 : 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 3),

        // Score Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            _getScoreDisplay(emp, l10n),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Podium Block
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withValues(alpha: isFirst ? 0.25 : 0.15),
                badgeColor.withValues(alpha: isFirst ? 0.10 : 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: isFirst ? 20 : 16,
                fontWeight: FontWeight.w900,
                color: badgeColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Rank Card for 4+ ───────────────────────────────────────────────────────
  Widget _buildRankCard({required int rank, required TopEmployee emp, required AppLocalizations l10n}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          // Rank Number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          _buildAvatarWidget(
            emp,
            radius: 16,
            badgeColor: AppColors.primary,
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              emp.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              _getScoreDisplay(emp, l10n),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
