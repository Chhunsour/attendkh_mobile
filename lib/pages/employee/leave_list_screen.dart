import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/leave_repository.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    ref.invalidate(leaveBalancesProvider);
    ref.invalidate(leaveRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(leaveBalancesProvider);
    final requestsAsync = ref.watch(leaveRequestsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final balances = balancesAsync.valueOrNull ?? const <LeaveBalance>[];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push(AppRoutes.leaveRequest);
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text(
          l10n.requestLeave,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          // The hero is scrolled under the status bar, so the spinner needs to
          // drop below it rather than sit on the notch.
          edgeOffset: MediaQuery.paddingOf(context).top + 8,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(
                  context,
                  l10n,
                  isDark,
                  balances,
                  loading: balancesAsync.isLoading,
                ),

                // Breakdown carousel only earns its space when there is more
                // than one type — a single type already lives in the hero.
                if (balances.length > 1) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 165,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: balances.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _LeaveBalanceCard(
                        balance: balances[i],
                        l10n: l10n,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: requestsAsync.when(
                    data: (requests) =>
                        _buildRequestsSection(requests, l10n, isDark),
                    loading: () => _buildRequestsLoading(isDark),
                    error: (e, _) => _buildErrorCard(l10n, isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Gradient hero: same slab treatment as the dashboard, carrying the
  // headline balance instead of a separate white card below it. ──
  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    List<LeaveBalance> balances, {
    required bool loading,
  }) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (context.canPop()) ...[
                      _heroIconButton(
                        Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        l10n.leaveManagement,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _heroIconButton(Icons.refresh_rounded, onTap: _refresh),
                  ],
                ),
                if (loading && balances.isEmpty) ...[
                  const SizedBox(height: 28),
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else if (balances.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _heroBalance(balances),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  // Headline: one type shows its own numbers, many types show the pooled
  // total with the per-type breakdown left to the carousel below.
  Widget _heroBalance(List<LeaveBalance> balances) {
    final single = balances.length == 1 ? balances.first : null;
    final total = balances.fold<double>(
      0,
      (sum, b) => sum + b.allocated + b.carriedForward,
    );
    final used = balances.fold<double>(0, (sum, b) => sum + b.used);
    final pending = balances.fold<double>(0, (sum, b) => sum + b.pending);
    final remaining = balances.fold<double>(0, (sum, b) => sum + b.remaining);
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          single != null && single.typeName.isNotEmpty
              ? single.typeName.toUpperCase()
              : '${_currentYear()} · ${balances.length} LEAVE TYPES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatDays(remaining),
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'days left of ${_formatDays(total)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _heroStat(
                'Allocated',
                '${_formatDays(total)}d',
                const Color(0xFF93C5FD),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _heroStat(
                'Used',
                '${_formatDays(used)}d',
                const Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _heroStat(
                'Pending',
                '${_formatDays(pending)}d',
                const Color(0xFF7DD3FC),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _currentYear() => DateTime.now().year.toString();

  Widget _heroStat(String label, String value, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Requests Section (History + Filter Bar) ──
  Widget _buildRequestsSection(
    List<LeaveRequest> requests,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final int allCount = requests.length;
    final int pendingCount = requests.where((r) => r.status.toLowerCase() == 'pending').length;
    final int approvedCount = requests.where((r) => r.status.toLowerCase() == 'approved').length;
    final int rejectedCount = requests.where((r) => r.status.toLowerCase() == 'rejected').length;

    final filtered = _filterRequests(requests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.history,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
                letterSpacing: -0.2,
              ),
            ),
            if (requests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242424)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$allCount ${l10n.total}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Senior UX/UI Filter Bar (Segmented Filter Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _filterChip('all', l10n.all, allCount, isDark),
              const SizedBox(width: 8),
              _filterChip('pending', l10n.pending, pendingCount, isDark),
              const SizedBox(width: 8),
              _filterChip('approved', l10n.approved, approvedCount, isDark),
              const SizedBox(width: 8),
              _filterChip('rejected', l10n.rejected, rejectedCount, isDark),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Filtered Request Cards List or Empty State
        if (filtered.isEmpty)
          _buildEmptyState(l10n, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _LeaveRequestCard(
                request: filtered[index],
                l10n: l10n,
                onCancelled: _refresh,
              );
            },
          ),
      ],
    );
  }

  List<LeaveRequest> _filterRequests(List<LeaveRequest> requests) {
    if (_selectedFilter == 'all') return requests;
    return requests.where((r) => r.status.toLowerCase() == _selectedFilter).toList();
  }

  Widget _filterChip(
    String key,
    String label,
    int count,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == key;

    final Color chipBg = isSelected
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF242424) : Colors.white);

    final Color chipBorder = isSelected
        ? (isDark ? const Color(0xFF3B82F6) : AppColors.primary)
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0));

    final Color chipTextColor = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    final Color countBg = isSelected
        ? (isDark ? const Color(0xFF2563EB).withValues(alpha: 0.30) : const Color(0xFFDBEAFE))
        : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF1F5F9));

    final Color countTextColor = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = key);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipBorder,
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: chipTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: countBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: countTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedFilter == 'all'
                ? l10n.noLeaveHistory
                : 'No ${_capitalize(_selectedFilter)} requests',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilter == 'all'
                ? 'Your requested leaves and balances will appear here.'
                : 'There are no leave requests under this filter status.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsLoading(bool isDark) {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 105,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              'Failed to load leave history',
              style: TextStyle(color: isDark ? AppColors.grey400 : AppColors.grey600),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDays(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ── Multi-Card Carousel Item ──
class _LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance balance;
  final AppLocalizations l10n;
  final bool isDark;

  const _LeaveBalanceCard({
    required this.balance,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = balance.remaining;
    final total = balance.allocated + balance.carriedForward;
    final used = balance.used;
    final baseColor = Color(
      int.tryParse(balance.color?.replaceFirst('#', 'FF') ?? 'FF0052FF') ??
          0xFF0052FF,
    );
    final value = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 5.5,
                  color: baseColor.withValues(alpha: isDark ? 0.20 : 0.12),
                ),
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5.5,
                  strokeCap: StrokeCap.round,
                  color: baseColor,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        remaining % 1 == 0
                            ? remaining.toInt().toString()
                            : remaining.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.grey900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'left',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            balance.typeName,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.grey900,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${used % 1 == 0 ? used.toInt() : used} / ${total % 1 == 0 ? total.toInt() : total} used',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clean, Modern Leave Request History Card ──
class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequest request;
  final AppLocalizations l10n;
  final VoidCallback onCancelled;

  const _LeaveRequestCard({
    required this.request,
    required this.l10n,
    required this.onCancelled,
  });

  Color get _statusColor {
    switch (request.status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return AppColors.grey400;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _typeIcon {
    final t = request.leaveType.toLowerCase();
    if (t.contains('sick') || t.contains('medical')) {
      return Icons.local_hospital_rounded;
    }
    if (t.contains('maternity') || t.contains('paternity')) {
      return Icons.child_friendly_rounded;
    }
    if (t.contains('annual') || t.contains('vacation')) {
      return Icons.beach_access_rounded;
    }
    if (t.contains('unpaid')) {
      return Icons.money_off_rounded;
    }
    return Icons.event_note_rounded;
  }

  String _formatSmartDateRange(String start, String end) {
    if (start.trim().isEmpty) return '—';
    try {
      final dtStart = DateTime.parse(start);
      final dtEnd = end.trim().isNotEmpty ? DateTime.parse(end) : dtStart;

      if (dtStart.year == dtEnd.year &&
          dtStart.month == dtEnd.month &&
          dtStart.day == dtEnd.day) {
        return DateFormat('dd MMM yyyy').format(dtStart);
      }

      if (dtStart.year == dtEnd.year && dtStart.month == dtEnd.month) {
        return '${DateFormat('dd').format(dtStart)} – ${DateFormat('dd MMM yyyy').format(dtEnd)}';
      }

      if (dtStart.year == dtEnd.year) {
        return '${DateFormat('dd MMM').format(dtStart)} – ${DateFormat('dd MMM yyyy').format(dtEnd)}';
      }

      return '${DateFormat('dd MMM yyyy').format(dtStart)} – ${DateFormat('dd MMM yyyy').format(dtEnd)}';
    } catch (_) {
      return '$start → $end';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDaysStr = request.days % 1 == 0
        ? request.days.toInt().toString()
        : request.days.toStringAsFixed(1);

    final bool isApproved = request.status.toLowerCase() == 'approved';
    final bool isPending = request.status.toLowerCase() == 'pending';
    final bool isRejected = request.status.toLowerCase() == 'rejected';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showDetailModal(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Icon, Title, Date Range & Status Badge
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_typeIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Title and Date Range
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.leaveType.isNotEmpty ? request.leaveType : 'Leave Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.grey900,
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12.5,
                                color: isDark ? AppColors.grey400 : AppColors.grey500,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _formatSmartDateRange(request.startDate, request.endDate),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge + Duration
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.20 : 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withValues(alpha: isDark ? 0.35 : 0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isApproved)
                                const Icon(Icons.check_rounded, size: 12, color: Color(0xFF10B981))
                              else if (isPending)
                                const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFF59E0B))
                              else if (isRejected)
                                const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
                              if (isApproved || isPending || isRejected)
                                const SizedBox(width: 3.5),
                              Text(
                                request.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.isHalfDay ? 'Half Day' : '$totalDaysStr ${request.days == 1 ? "day" : "days"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reason Note Strip
              if (request.reason != null && request.reason!.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            request.reason!.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.grey300 : AppColors.grey700,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Footer: Attachment & Cancel Action Bar
              if (isPending || (request.documentUrl != null && request.documentUrl!.isNotEmpty))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (request.documentUrl != null && request.documentUrl!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.attachmentIncluded,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      if (isPending)
                        InkWell(
                          onTap: () => _confirmCancel(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.cancel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  void _showDetailModal(BuildContext context) {
    final statusColor = _statusColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey600 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.leaveType.isNotEmpty ? request.leaveType : 'Leave Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(context, Icons.calendar_month_rounded, 'Date Range', _formatSmartDateRange(request.startDate, request.endDate), isDark),
              _detailRow(context, Icons.timer_outlined, 'Total Duration', request.isHalfDay ? 'Half Day' : '${request.days} days', isDark),
              if (request.createdAt.isNotEmpty)
                _detailRow(context, Icons.access_time_rounded, 'Applied On', _formatDate(request.createdAt), isDark),
              if (request.approvedBy != null && request.approvedBy!.isNotEmpty)
                _detailRow(context, Icons.verified_user_outlined, 'Reviewed By', request.approvedBy!, isDark),
              if (request.reason != null && request.reason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reason / Remarks',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    request.reason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.grey800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.grey400 : AppColors.grey500),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dtStr) {
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequest),
        content: Text(l10n.cancelLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.yesCancel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = LeaveRepository();
        await repo.cancelRequest(request.id);
        onCancelled();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.leaveRequestCancelled),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${e.toString()}'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
