import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddManualModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualAttendanceModal(
        onSaved: () {
          ref.invalidate(allAttendanceLogsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final pendingCorrections = correctionsAsync.maybeWhen(
      data: (items) => items.where((i) => i.status == 'pending').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.attendanceLogsTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Manual Attendance',
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF10B981),
            ),
            onPressed: () => _openAddManualModal(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            onPressed: () {
              ref.invalidate(allAttendanceLogsProvider);
              ref.invalidate(attendanceCorrectionsProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface(context),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF10B981),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFF10B981),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabDailyLogs),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabCorrections),
                      if (pendingCorrections > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCorrections',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_DailyLogsTab(), _CorrectionsTab()],
      ),
    );
  }
}

class _DailyLogsTab extends ConsumerStatefulWidget {
  const _DailyLogsTab();

  @override
  ConsumerState<_DailyLogsTab> createState() => _DailyLogsTabState();
}

class _DailyLogsTabState extends ConsumerState<_DailyLogsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(allAttendanceLogsProvider);
    final l10n = AppLocalizations.of(context)!;

    return logsAsync.when(
      data: (items) {
        int total = items.length;
        int present = items.where((i) => i.status == 'present').length;
        int lateCount = items.where((i) => i.status == 'late').length;
        int absent = items.where((i) => i.status == 'absent').length;
        int onLeave = items
            .where((i) => i.status == 'on_leave' || i.status == 'leave')
            .length;

        final filteredItems = items.where((item) {
          final matchesSearch = item.employeeName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final matchesStatus =
              _selectedStatus == 'all' || item.status == _selectedStatus;
          return matchesSearch && matchesStatus;
        }).toList();

        return RefreshIndicator(
          color: const Color(0xFF10B981),
          onRefresh: () async => ref.invalidate(allAttendanceLogsProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Overview Metric Cards ──
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total',
                              value: '$total',
                              icon: Icons.list_alt_rounded,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Present',
                              value: '$present',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Late',
                              value: '$lateCount',
                              icon: Icons.timer_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Absent',
                              value: '$absent',
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'On Leave',
                              value: '$onLeave',
                              icon: Icons.beach_access_rounded,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Search Field ──
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textPrimary(context),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search employee name...',
                            hintStyle: const TextStyle(
                              color: AppColors.grey400,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.grey400,
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.grey400,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Status Filter Chips ──
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All ($total)'),
                            _buildFilterChip('present', 'Present ($present)'),
                            _buildFilterChip('late', 'Late ($lateCount)'),
                            _buildFilterChip('absent', 'Absent ($absent)'),
                            _buildFilterChip('on_leave', 'On Leave ($onLeave)'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // ── Lazy Virtualized List of Records ──
              if (filteredItems.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.grey200.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.fingerprint_rounded,
                            size: 48,
                            color: AppColors.grey300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No logs matching "$_searchQuery"'
                                : l10n.noAttendanceRecords,
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final c = filteredItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAttendanceCard(context, ref, c, l10n),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.failedToLoadEmployees,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allAttendanceLogsProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.grey500,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : AppColors.grey200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.grey700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    WidgetRef ref,
    AdminAttendanceRecord c,
    AppLocalizations l10n,
  ) {
    final (statusColor, statusBg) = switch (c.status) {
      'present' => (const Color(0xFF10B981), const Color(0xFFECFDF5)),
      'late' => (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      'early_leave' => (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      'on_leave' ||
      'leave' => (const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _ => (const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
    };

    final hasUnapprovedEarlyIn =
        (c.earlyClockInMinutes ?? 0) > 0 &&
        (c.approvedPreShiftOtMinutes ?? 0) == 0 &&
        c.canApprovePreShiftOt;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRecordDetailsSheet(context, ref, c),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.employeeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            formatDate(c.date),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.status.isEmpty
                            ? 'Unknown'
                            : (c.status[0].toUpperCase() +
                                  c.status.substring(1).replaceAll('_', ' ')),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Timestamps Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.clockIn != null
                                  ? formatTime(c.clockIn)
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 14, color: AppColors.grey300),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 14,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.clockOut != null
                                  ? formatTime(c.clockOut)
                                  : '--:--',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if ((c.lateMinutes ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ Late arrival: ${c.lateMinutes} mins',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                if ((c.earlyClockInMinutes ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0EA5E9,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${l10n.earlyIn}: ${c.earlyClockInMinutes! ~/ 60}h ${c.earlyClockInMinutes! % 60}m',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if ((c.approvedPreShiftOtMinutes ?? 0) > 0)
                        Text(
                          '${l10n.approved}: ${c.approvedPreShiftOtMinutes! ~/ 60}h ${c.approvedPreShiftOtMinutes! % 60}m',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],

                if (hasUnapprovedEarlyIn) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApproveOt(context, ref, c.id),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: Text(
                        l10n.approvePreShiftOT,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    AdminAttendanceRecord c,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 18,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  c.employeeName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.grey500,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              'Date: ${c.date}',
              style: const TextStyle(color: AppColors.grey500, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (c.clockInPhoto != null) ...[
              Text(
                'Clock-In Photo Verification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl:
                      '${DioClient.storageUrl}/${c.clockInPhoto!.startsWith('/') ? c.clockInPhoto!.substring(1) : c.clockInPhoto!}',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    height: 100,
                    color: AppColors.grey100,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 40,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Notes: ${c.notes}',
                  style: const TextStyle(
                    color: AppColors.grey700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteRecord(context, ref, c.id);
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
                label: const Text(
                  'Delete Attendance Log',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    try {
      await ref.read(adminOpsRepositoryProvider).deleteAttendance(id);
      ref.invalidate(allAttendanceLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance record deleted.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveOt(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminOpsRepositoryProvider).approveOvertime(id);
      ref.invalidate(allAttendanceLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.preShiftOtApprovedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _CorrectionsTab extends ConsumerWidget {
  const _CorrectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final l10n = AppLocalizations.of(context)!;

    return correctionsAsync.when(
      data: (items) => items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noPendingCorrections,
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              onRefresh: () async =>
                  ref.invalidate(attendanceCorrectionsProvider),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final (statusColor, statusBg) = switch (c.status) {
                    'approved' => (
                      const Color(0xFF10B981),
                      const Color(0xFFECFDF5),
                    ),
                    'rejected' => (
                      const Color(0xFFEF4444),
                      const Color(0xFFFEF2F2),
                    ),
                    _ => (const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                  };

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.grey200.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_calendar_rounded,
                                color: statusColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.employeeName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    formatDate(c.date),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.status.isEmpty
                                    ? 'Unknown'
                                    : (c.status[0].toUpperCase() +
                                          c.status.substring(1)),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (c.clockIn != null || c.clockOut != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                if (c.clockIn != null)
                                  Expanded(
                                    child: Text(
                                      '${l10n.inTime}: ${formatTime(c.clockIn)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                if (c.clockOut != null)
                                  Expanded(
                                    child: Text(
                                      '${l10n.outTime}: ${formatTime(c.clockOut)}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (c.reason != null && c.reason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${l10n.reason}: ${c.reason}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                        ],
                        if (c.status == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: OutlinedButton(
                                    onPressed: () => _handleAction(
                                      context,
                                      ref,
                                      c.id,
                                      false,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: BorderSide(
                                        color: AppColors.danger.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.reject,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _handleAction(context, ref, c.id, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      l10n.approve,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(attendanceCorrectionsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    int id,
    bool approve,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (approve) {
        await ref.read(adminOpsRepositoryProvider).approveCorrection(id);
      } else {
        await ref.read(adminOpsRepositoryProvider).rejectCorrection(id);
      }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? l10n.correctionApprovedSuccess
                  : l10n.correctionRejectedSuccess,
            ),
            backgroundColor: approve ? AppColors.success : AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ManualAttendanceModal extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _ManualAttendanceModal({required this.onSaved});

  @override
  ConsumerState<_ManualAttendanceModal> createState() =>
      _ManualAttendanceModalState();
}

class _ManualAttendanceModalState
    extends ConsumerState<_ManualAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );
  final _clockInController = TextEditingController();
  final _clockOutController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'present';
  bool _isSaving = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _dateController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      await repo.addManualAttendance({
        'employee_id': _employeeIdController.text.trim(),
        'date': _dateController.text.trim(),
        'clock_in': _clockInController.text.trim().isEmpty
            ? null
            : _clockInController.text.trim(),
        'clock_out': _clockOutController.text.trim().isEmpty
            ? null
            : _clockOutController.text.trim(),
        'status': _status,
        'notes': _notesController.text.trim(),
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual attendance record added.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom:
            MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom +
            20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Attendance Entry',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.grey500,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeIdController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Employee ID (Number)',
                  Icons.badge_outlined,
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter employee ID'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: _inputDecoration(
                  'Date (YYYY-MM-DD)',
                  Icons.calendar_today_outlined,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter date' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clockInController,
                      decoration: _inputDecoration(
                        'Clock In (HH:MM)',
                        Icons.login_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _clockOutController,
                      decoration: _inputDecoration(
                        'Clock Out (HH:MM)',
                        Icons.logout_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _inputDecoration(
                  'Status',
                  Icons.check_circle_outline_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'late', child: Text('Late')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(
                  'Notes / Reason',
                  Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Attendance Record',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.grey500),
      prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981)),
      ),
      filled: true,
      fillColor: AppColors.grey50,
    );
  }
}
