import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/utils/utils/date_format_utils.dart';

class DailyLogsTab extends ConsumerStatefulWidget {
  const DailyLogsTab({super.key});

  @override
  ConsumerState<DailyLogsTab> createState() => _DailyLogsTabState();
}

class _DailyLogsTabState extends ConsumerState<DailyLogsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  AttendanceFilters _filters = const AttendanceFilters();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filters.dateFrom != null && _filters.dateFrom!.isNotEmpty) count++;
    if (_filters.dateTo != null && _filters.dateTo!.isNotEmpty) count++;
    if (_filters.departmentId != null) count++;
    if (_filters.employeeId != null) count++;
    if (_selectedStatus != 'all') count++;
    return count;
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    String? from;
    String? to;
    if (preset == 'today') {
      from = now.toIso8601String().substring(0, 10);
      to = from;
    } else if (preset == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      from = y.toIso8601String().substring(0, 10);
      to = from;
    } else if (preset == 'week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      from = monday.toIso8601String().substring(0, 10);
      to = now.toIso8601String().substring(0, 10);
    } else if (preset == 'month') {
      from = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      to = now.toIso8601String().substring(0, 10);
    }
    setState(() {
      _filters = _filters.copyWith(
        dateFrom: () => from,
        dateTo: () => to,
      );
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_filters.dateFrom != null && _filters.dateTo != null)
          ? DateTimeRange(
              start: DateTime.tryParse(_filters.dateFrom!) ?? DateTime.now(),
              end: DateTime.tryParse(_filters.dateTo!) ?? DateTime.now(),
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: AppColors.grey900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _filters = _filters.copyWith(
          dateFrom: () => picked.start.toIso8601String().substring(0, 10),
          dateTo: () => picked.end.toIso8601String().substring(0, 10),
        );
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _selectedStatus = 'all';
      _filters = const AttendanceFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(allAttendanceLogsProvider(_filters));
    final departmentsAsync = ref.watch(departmentsProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);

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

                      // ── Search & Filter Toggle Bar ──
                      Row(
                        children: [
                          Expanded(
                            child: Container(
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
                          ),
                          const SizedBox(width: 8),
                          // Filter Button
                          InkWell(
                            onTap: () => setState(() => _showFilters = !_showFilters),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _showFilters || _activeFilterCount > 0
                                    ? const Color(0xFF10B981)
                                    : AppColors.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _showFilters || _activeFilterCount > 0
                                      ? const Color(0xFF10B981)
                                      : AppColors.border(context),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: _showFilters || _activeFilterCount > 0
                                        ? Colors.white
                                        : AppColors.grey600,
                                  ),
                                  if (_activeFilterCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$_activeFilterCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Collapsible Filter Drawer ──
                      if (_showFilters) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_activeFilterCount > 0)
                                    TextButton(
                                      onPressed: _clearFilters,
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: AppColors.danger,
                                      ),
                                      child: Text(l10n.resetAll, style: const TextStyle(fontSize: 12)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Date Range Presets
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildPresetChip('today', 'Today'),
                                    _buildPresetChip('yesterday', 'Yesterday'),
                                    _buildPresetChip('week', 'This Week'),
                                    _buildPresetChip('month', 'This Month'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Date Pickers Row
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickDateRange,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF10B981)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _filters.dateFrom ?? 'Date From',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _filters.dateFrom != null ? AppColors.grey900 : AppColors.grey500,
                                                  fontWeight: _filters.dateFrom != null ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickDateRange,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF10B981)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _filters.dateTo ?? 'Date To',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _filters.dateTo != null ? AppColors.grey900 : AppColors.grey500,
                                                  fontWeight: _filters.dateTo != null ? FontWeight.bold : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Department Dropdown
                              departmentsAsync.when(
                                data: (depts) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _filters.departmentId,
                                      isExpanded: true,
                                      hint: const Text('All Departments', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('All Departments', style: TextStyle(fontSize: 12)),
                                        ),
                                        ...depts.map((d) => DropdownMenuItem<int?>(
                                          value: d.id,
                                          child: Text(d.name, style: const TextStyle(fontSize: 12)),
                                        )),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _filters = _filters.copyWith(departmentId: () => val);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (e, s) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 10),

                              // Employee Dropdown
                              employeesAsync.when(
                                data: (employees) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _filters.employeeId,
                                      isExpanded: true,
                                      hint: const Text('All Employees', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('All Employees', style: TextStyle(fontSize: 12)),
                                        ),
                                        ...employees.map((e) => DropdownMenuItem<int?>(
                                          value: e.id,
                                          child: Text(
                                            '${e.fullName} (${e.employeeId ?? '#${e.id}'})',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        )),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _filters = _filters.copyWith(employeeId: () => val);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (e, s) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ],

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
                          if (_activeFilterCount > 0 || _searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _clearFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(l10n.clearFilters, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
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

  Widget _buildPresetChip(String preset, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _setDatePreset(preset),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
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