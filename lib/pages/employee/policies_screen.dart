import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final employeePoliciesProvider =
    FutureProvider.autoDispose<List<Policy>>((ref) async {
  final repo = PoliciesRepository();
  return repo.getEmployeePolicies();
});

class PoliciesScreen extends ConsumerStatefulWidget {
  const PoliciesScreen({super.key});

  @override
  ConsumerState<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends ConsumerState<PoliciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    HapticFeedback.lightImpact();
    ref.invalidate(employeePoliciesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(employeePoliciesProvider);
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
        body: policiesAsync.when(
          loading: () => Center(
            child: LoadingIndicator(message: l10n.loading),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: isDark ? AppColors.grey600 : AppColors.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load policies: $err',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (policies) {
            final filtered = _search.isEmpty
                ? policies
                : policies
                    .where((p) =>
                        p.title
                            .toLowerCase()
                            .contains(_search.toLowerCase()) ||
                        p.content
                            .toLowerCase()
                            .contains(_search.toLowerCase()))
                    .toList();

            final unread = filtered.where((p) => !p.isAcknowledged).toList();
            final read = filtered.where((p) => p.isAcknowledged).toList();

            final totalUnreadCount =
                policies.where((p) => !p.isAcknowledged).length;
            final totalReadCount =
                policies.where((p) => p.isAcknowledged).length;

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              color: AppColors.primary,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildRoyalHeroHeader(
                        context: context,
                        l10n: l10n,
                        unreadCount: totalUnreadCount,
                        readCount: totalReadCount,
                        isDark: isDark,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: _buildSearchBar(context, l10n, isDark),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPolicyList(
                      unread,
                      emptyTitle: l10n.allPoliciesAcknowledged,
                      emptySubtitle:
                          'Great job! You have read and acknowledged all required policies.',
                      l10n: l10n,
                      isUnreadList: true,
                      isDark: isDark,
                    ),
                    _buildPolicyList(
                      read,
                      emptyTitle: l10n.noPoliciesAcknowledged,
                      emptySubtitle:
                          'Policies you have signed and acknowledged will appear here.',
                      l10n: l10n,
                      isUnreadList: false,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
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
    required int unreadCount,
    required int readCount,
    required bool isDark,
  }) {
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
                children: [
                  // ── Top Navigation Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (context.canPop())
                        _frostedHeroButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => context.pop(),
                        )
                      else
                        const SizedBox(width: 40),
                      Text(
                        l10n.companyPolicies,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      _frostedHeroButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onTap: _refresh,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Metric Summary Cards Row ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.pending_actions_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: const Color(0xFFFEF3C7),
                          title: l10n.actionRequired,
                          count: '$unreadCount',
                          isSelected: _tabController.index == 0,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _tabController.animateTo(0);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.verified_rounded,
                          iconColor: const Color(0xFF10B981),
                          iconBg: const Color(0xFFD1FAE5),
                          title: l10n.acknowledged,
                          count: '$readCount',
                          isSelected: _tabController.index == 1,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _tabController.animateTo(1);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Frosted Segmented TabBar ──
                  Container(
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: const Color(0xFF0052FF),
                      unselectedLabelColor:
                          Colors.white.withValues(alpha: 0.85),
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.actionRequired),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 0
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white
                                            .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: _tabController.index == 0
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(l10n.acknowledged),
                              if (readCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 1
                                        ? const Color(0xFF10B981)
                                        : Colors.white
                                            .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$readCount',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.18),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Search & Filter Bar ──
  Widget _buildSearchBar(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _search = val.trim()),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchPoliciesHint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.grey500 : AppColors.grey400,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
            size: 22,
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                    size: 18,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Policy List & Card Renderer ──
  Widget _buildPolicyList(
    List<Policy> policies, {
    required String emptyTitle,
    required String emptySubtitle,
    required AppLocalizations l10n,
    required bool isUnreadList,
    required bool isDark,
  }) {
    if (policies.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isUnreadList
                      ? const Color(0xFF10B981)
                          .withValues(alpha: isDark ? 0.18 : 0.10)
                      : const Color(0xFF38BDF8)
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnreadList
                      ? Icons.verified_user_rounded
                      : Icons.library_books_rounded,
                  size: 36,
                  color: isUnreadList
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
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
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
      itemCount: policies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final policy = policies[index];
        return _buildPolicyCard(policy, l10n, isDark);
      },
    );
  }

  Widget _buildPolicyCard(
    Policy policy,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: policy.isAcknowledged
              ? (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))
              : const Color(0xFFF59E0B)
                  .withValues(alpha: isDark ? 0.35 : 0.30),
          width: policy.isAcknowledged ? 1.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _openPolicyDetail(policy, l10n);
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Squircle Icon Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: policy.isAcknowledged
                          ? (isDark
                              ? [
                                  const Color(0xFF064E3B)
                                      .withValues(alpha: 0.5),
                                  const Color(0xFF047857)
                                      .withValues(alpha: 0.3),
                                ]
                              : [
                                  const Color(0xFFD1FAE5),
                                  const Color(0xFFA7F3D0),
                                ])
                          : (isDark
                              ? [
                                  const Color(0xFF78350F)
                                      .withValues(alpha: 0.5),
                                  const Color(0xFFB45309)
                                      .withValues(alpha: 0.3),
                                ]
                              : [
                                  const Color(0xFFFEF3C7),
                                  const Color(0xFFFDE68A),
                                ]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: policy.isAcknowledged
                          ? const Color(0xFF10B981)
                              .withValues(alpha: isDark ? 0.35 : 0.25)
                          : const Color(0xFFF59E0B)
                              .withValues(alpha: isDark ? 0.35 : 0.25),
                    ),
                  ),
                  child: Icon(
                    policy.isAcknowledged
                        ? Icons.verified_rounded
                        : Icons.assignment_late_rounded,
                    color: policy.isAcknowledged
                        ? (isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF059669))
                        : (isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFD97706)),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Content Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.grey900,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Chips Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Version Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDarkElevated
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${l10n.version}${policy.version}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.grey300
                                    : AppColors.grey700,
                              ),
                            ),
                          ),

                          // Department Chip
                          if (policy.department != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: isDark ? 0.20 : 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                policy.department!.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),

                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: policy.isAcknowledged
                                  ? const Color(0xFF10B981).withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    )
                                  : const Color(0xFFF59E0B).withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  policy.isAcknowledged
                                      ? Icons.check_circle_rounded
                                      : Icons.circle,
                                  size: 8,
                                  color: policy.isAcknowledged
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  policy.isAcknowledged
                                      ? l10n.acknowledged
                                      : l10n.actionRequired,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: policy.isAcknowledged
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPolicyDetail(Policy policy, AppLocalizations l10n) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PolicyDetailScreen(
          policy: policy,
          l10n: l10n,
          onAcknowledged: () {
            ref.invalidate(employeePoliciesProvider);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Redesigned Policy Detail Screen ──
// ─────────────────────────────────────────────────────────────────────────────
class PolicyDetailScreen extends StatefulWidget {
  final Policy policy;
  final VoidCallback onAcknowledged;
  final AppLocalizations l10n;

  const PolicyDetailScreen({
    super.key,
    required this.policy,
    required this.onAcknowledged,
    required this.l10n,
  });

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  bool _submitting = false;

  Future<void> _handleAcknowledge() async {
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final repo = PoliciesRepository();
      await repo.acknowledgePolicy(widget.policy.id);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.l10n.policyAcknowledgedSuccess,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onAcknowledged();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: Column(
          children: [
            // ── Royal Blue Header ──
            _buildDetailHeader(context, isDark),

            // ── Content Area ──
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Policy Header Meta Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.20 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.policy.title,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : AppColors.grey900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDarkElevated
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${widget.l10n.version}${widget.policy.version}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.grey300
                                        : AppColors.grey700,
                                  ),
                                ),
                              ),
                              if (widget.policy.department != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(
                                            alpha: isDark ? 0.20 : 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.policy.department!.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              if (widget.policy.effectiveDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(
                                            alpha: isDark ? 0.20 : 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Effective: ${widget.policy.effectiveDate!.split("T").first}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Document Content Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.20 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.policy.content,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : AppColors.grey800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Area ──
            _buildBottomAction(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8),
            Color(0xFF0052FF),
            Color(0xFF1E6BFF),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.l10n.policyDocument,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    if (widget.policy.isAcknowledged) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981)
                  .withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981)
                    .withValues(alpha: isDark ? 0.35 : 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${widget.l10n.acknowledgedOn} ${widget.policy.acknowledgedAt?.split("T").first ?? DateFormat("yyyy-MM-dd").format(DateTime.now())}',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _handleAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.l10n.iHaveReadAndAcknowledge,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
