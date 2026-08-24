import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_detail_screen.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

/// One cut corner on every card — the motif the admin surfaces share.
const _cardShape = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(20),
  bottomLeft: Radius.circular(6),
);
const _chipShape = BorderRadius.only(
  topLeft: Radius.circular(14),
  topRight: Radius.circular(14),
  bottomRight: Radius.circular(14),
  bottomLeft: Radius.circular(5),
);

// ── Status config ────────────────────────────────────────────────────────────
const _statusConfig = {
  'active': _StatusCfg(
    Color(0xFF10B981),
    Color(0xFFECFDF5),
    Icons.check_circle_rounded,
  ),
  'inactive': _StatusCfg(
    Color(0xFF64748B),
    Color(0xFFF1F5F9),
    Icons.pause_circle_rounded,
  ),
  'terminated': _StatusCfg(
    Color(0xFFEF4444),
    Color(0xFFFEF2F2),
    Icons.cancel_rounded,
  ),
  'resigned': _StatusCfg(
    Color(0xFFF59E0B),
    Color(0xFFFFFBEB),
    Icons.logout_rounded,
  ),
  'on_leave': _StatusCfg(
    Color(0xFF0EA5E9),
    Color(0xFFF0F9FF),
    Icons.beach_access_rounded,
  ),
};

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.color, this.bg, this.icon);
}

String _getLocalizedType(String type, AppLocalizations l10n) {
  switch (type) {
    case 'full_time':
      return l10n.fullTime;
    case 'part_time':
      return l10n.partTime;
    case 'contract':
      return l10n.contract;
    case 'intern':
      return l10n.intern;
    default:
      return type;
  }
}

// Avatar background colors (cycling)
const _avatarColors = [
  Color(0xFFEEF2FF), // indigo
  Color(0xFFE0F2FE), // sky
  Color(0xFFECFDF5), // emerald
  Color(0xFFFAF5FF), // purple
  Color(0xFFFFFBEB), // amber
];
const _avatarFgColors = [
  Color(0xFF6366F1),
  Color(0xFF0284C7),
  Color(0xFF059669),
  Color(0xFF7C3AED),
  Color(0xFFD97706),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  EmployeeFilters _filters = const EmployeeFilters();
  String _searchQuery = '';
  bool _showFilters = false;
  bool _sortAscending = true;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.trim().toLowerCase());
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _filters = const EmployeeFilters();
      _showFilters = false;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filters.departmentId != null) count++;
    if (_filters.branchId != null) count++;
    if (_filters.employmentStatus.isNotEmpty) count++;
    if (_filters.employmentType.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(adminEmployeesProvider(_filters));
    final departmentsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      // ── App Bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.employeeDirectory,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminEmployeesProvider(_filters)),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminEmployeesProvider(_filters)),
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
                    // ── Metric Snapshot ───────────────────────────────────────────────
                    employeesAsync.maybeWhen(
                      data: (employees) {
                        final total = employees.length;
                        final active = employees
                            .where(
                              (e) =>
                                  (e.employmentStatus ??
                                      e.status ??
                                      'active') ==
                                  'active',
                            )
                            .length;
                        final onLeave = employees
                            .where(
                              (e) =>
                                  (e.employmentStatus ?? e.status) ==
                                  'on_leave',
                            )
                            .length;
                        final other = total - active - onLeave;

                        return _buildStatStrip(
                          l10n,
                          total: total,
                          active: active,
                          onLeave: onLeave,
                          other: other,
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 14),

                    // ── Search & Filter Toggle Bar ────────────────────────────────────
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: _cardShape,
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Search field
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _onSearchChanged,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary(context),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.searchEmployeesHint,
                                    hintStyle: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey400,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: AppColors.grey400,
                                    ),
                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 16,
                                              color: AppColors.grey500,
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
                              // Filter toggle button
                              GestureDetector(
                                onTap: () => setState(
                                  () => _showFilters = !_showFilters,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _showFilters
                                        ? const Color(
                                            0xFF0EA5E9,
                                          ).withValues(alpha: 0.12)
                                        : AppColors.grey50,
                                    borderRadius: _chipShape,
                                    border: Border.all(
                                      color: _showFilters
                                          ? const Color(0xFF0EA5E9)
                                          : AppColors.grey200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 16,
                                        color: _showFilters
                                            ? const Color(0xFF0EA5E9)
                                            : AppColors.grey600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.filter,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _showFilters
                                              ? const Color(0xFF0EA5E9)
                                              : AppColors.grey700,
                                        ),
                                      ),
                                      if (_activeFilterCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0EA5E9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$_activeFilterCount',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
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

                          // ── Animated Filter Drawer ──
                          if (_showFilters) ...[
                            const Divider(color: AppColors.grey200, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _FilterDropdown<int?>(
                                          label: l10n.department,
                                          value: _filters.departmentId,
                                          hint: l10n.allDepartments,
                                          items: departmentsAsync.maybeWhen(
                                            data: (depts) => depts
                                                .map(
                                                  (d) => DropdownMenuItem<int?>(
                                                    value: d.id,
                                                    child: Text(d.name),
                                                  ),
                                                )
                                                .toList(),
                                            orElse: () => [],
                                          ),
                                          onChanged: (v) => setState(
                                            () => _filters = _filters.copyWith(
                                              departmentId: v,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _FilterDropdown<int?>(
                                          label: l10n.branch,
                                          value: _filters.branchId,
                                          hint: l10n.allBranches,
                                          items: branchesAsync.maybeWhen(
                                            data: (branches) => branches
                                                .map(
                                                  (b) => DropdownMenuItem<int?>(
                                                    value: b.id,
                                                    child: Text(b.name),
                                                  ),
                                                )
                                                .toList(),
                                            orElse: () => [],
                                          ),
                                          onChanged: (v) => setState(
                                            () => _filters = _filters.copyWith(
                                              branchId: v,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _FilterDropdown<String>(
                                          label: l10n.status,
                                          value:
                                              _filters.employmentStatus.isEmpty
                                              ? ''
                                              : _filters.employmentStatus,
                                          hint: l10n.allStatuses,
                                          items: [
                                            DropdownMenuItem(
                                              value: '',
                                              child: Text(l10n.allStatuses),
                                            ),
                                            ..._statusConfig.keys.map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                  s
                                                      .replaceAll('_', ' ')
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) => setState(
                                            () => _filters = _filters.copyWith(
                                              employmentStatus: v ?? '',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _FilterDropdown<String>(
                                          label: l10n.type,
                                          value: _filters.employmentType.isEmpty
                                              ? ''
                                              : _filters.employmentType,
                                          hint: l10n.allTypes,
                                          items: [
                                            DropdownMenuItem(
                                              value: '',
                                              child: Text(l10n.allTypes),
                                            ),
                                            ...[
                                              'full_time',
                                              'part_time',
                                              'contract',
                                              'intern',
                                            ].map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(
                                                  _getLocalizedType(type, l10n),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (v) => setState(
                                            () => _filters = _filters.copyWith(
                                              employmentType: v ?? '',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_filters.hasActiveFilters) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        onPressed: _clearFilters,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: BorderSide(
                                            color: AppColors.danger.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 14,
                                        ),
                                        label: Text(
                                          l10n.clearAllFilters,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Sort & Results Header ─────────────────────────────────────────
                    employeesAsync.maybeWhen(
                      data: (employees) {
                        final filtered = employees.where((e) {
                          if (_searchQuery.isEmpty) return true;
                          final name = e.name.toLowerCase();
                          final khmerName = (e.khmerName ?? '').toLowerCase();
                          final empId = (e.employeeId ?? '').toLowerCase();
                          final email = (e.email ?? '').toLowerCase();
                          final phone = (e.phone ?? '').toLowerCase();
                          final dept = (e.department ?? '').toLowerCase();
                          final pos = (e.position ?? '').toLowerCase();
                          return name.contains(_searchQuery) ||
                              khmerName.contains(_searchQuery) ||
                              empId.contains(_searchQuery) ||
                              email.contains(_searchQuery) ||
                              phone.contains(_searchQuery) ||
                              dept.contains(_searchQuery) ||
                              pos.contains(_searchQuery);
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Text(
                                l10n.employeeCount(
                                  filtered.length,
                                  filtered.length != 1 ? 's' : '',
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => setState(
                                  () => _sortAscending = !_sortAscending,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _sortAscending
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 13,
                                        color: AppColors.grey700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _sortAscending ? 'A-Z' : 'Z-A',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.grey700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Lazy Virtualized Employee List ────────────────────────────────
            employeesAsync.when(
              data: (employees) {
                final filtered = employees.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  final name = e.name.toLowerCase();
                  final khmerName = (e.khmerName ?? '').toLowerCase();
                  final empId = (e.employeeId ?? '').toLowerCase();
                  final email = (e.email ?? '').toLowerCase();
                  final phone = (e.phone ?? '').toLowerCase();
                  final dept = (e.department ?? '').toLowerCase();
                  final pos = (e.position ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      khmerName.contains(_searchQuery) ||
                      empId.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      dept.contains(_searchQuery) ||
                      pos.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyState(
                        hasFilters:
                            _filters.hasActiveFilters || _searchQuery.isNotEmpty,
                        onClear: _clearFilters,
                        l10n: l10n,
                      ),
                    ),
                  );
                }
                final sorted = List.of(filtered)
                  ..sort((a, b) {
                    final cmp = a.name.toLowerCase().compareTo(
                      b.name.toLowerCase(),
                    );
                    return _sortAscending ? cmp : -cmp;
                  });
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final emp = sorted[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EmployeeCard(
                          employee: emp,
                          colorIndex: index % _avatarColors.length,
                          l10n: l10n,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: _ErrorState(
                    onRetry: () =>
                        ref.invalidate(adminEmployeesProvider(_filters)),
                    l10n: l10n,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminEmployeeForm),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: _cardShape),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          l10n.addEmployee,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
    );
  }

  /// One hairline-divided slab instead of four outlined boxes — and every
  /// cell is a filter, so the numbers do something instead of just sitting
  /// there. Tapping the active cell clears the filter again.
  Widget _buildStatStrip(
    AppLocalizations l10n, {
    required int total,
    required int active,
    required int onLeave,
    required int other,
  }) {
    final line = AppColors.border(context);
    final cells = [
      (l10n.totalStaff, total, const Color(0xFF0EA5E9), ''),
      (l10n.active, active, const Color(0xFF10B981), 'active'),
      (l10n.onLeave, onLeave, const Color(0xFFF59E0B), 'on_leave'),
      (l10n.inactive, other, const Color(0xFF64748B), 'inactive'),
    ];

    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: line),
        borderRadius: _cardShape,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0) Container(width: 1, color: line),
              Expanded(
                child: _statCell(
                  label: cell.$1,
                  value: cell.$2,
                  color: cell.$3,
                  status: cell.$4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCell({
    required String label,
    required int value,
    required Color color,
    required String status,
  }) {
    final selected = status.isNotEmpty && _filters.employmentStatus == status;
    final muted = value == 0 && !selected;

    return InkWell(
      onTap: status.isEmpty
          ? null
          : () => setState(
              () => _filters = _filters.copyWith(
                employmentStatus: selected ? '' : status,
              ),
            ),
      child: Container(
        color: selected ? color.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
                color: muted ? AppColors.grey400 : color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? color : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Employee Card ─────────────────────────────────────────────────────────────
class _EmployeeCard extends ConsumerWidget {
  final EmployeeData employee;
  final int colorIndex;
  final AppLocalizations l10n;
  const _EmployeeCard({
    required this.employee,
    required this.colorIndex,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = employee.employmentStatus ?? employee.status ?? 'active';
    final type = employee.employmentType ?? '';
    final cfg =
        _statusConfig[status] ??
        const _StatusCfg(
          Color(0xFF6B7280),
          Color(0xFFF3F4F6),
          Icons.help_outline_rounded,
        );
    final typeLabel = _getLocalizedType(type, l10n);
    final avatarBg = _avatarColors[colorIndex];
    final avatarFg = _avatarFgColors[colorIndex];

    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border(context)),
        borderRadius: _cardShape,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminEmployeeDetailScreen(employee: employee),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status rail — the whole card is colour-coded before you read it
              Container(width: 4, color: cfg.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 13, 6, 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar ───────────────────────────────────────────
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: avatarBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cfg.color.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: employee.avatar != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          employee.avatar!.startsWith('http')
                                          ? employee.avatar!
                                          : '${DioClient.storageUrl}/${employee.avatar!.startsWith('/') ? employee.avatar!.substring(1) : employee.avatar!}',
                                      fit: BoxFit.cover,
                                      memCacheWidth: 160,
                                      memCacheHeight: 160,
                                      maxWidthDiskCache: 300,
                                      maxHeightDiskCache: 300,
                                      placeholder: (ctx, url) => Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: avatarFg.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (ctx, url, err) => Center(
                                        child: Text(
                                          _initials(employee),
                                          style: TextStyle(
                                            color: avatarFg,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initials(employee),
                                      style: TextStyle(
                                        color: avatarFg,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: cfg.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface(context),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // ── Info ──────────────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    employee.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (employee.employeeId != null) ...[
                                  const SizedBox(width: 7),
                                  Text(
                                    employee.employeeId!,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.grey400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Status + type badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cfg.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cfg.icon,
                                        size: 10,
                                        color: cfg.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                          color: cfg.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (typeLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey500.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (employee.position != null)
                              _MetaRow(
                                icon: Icons.work_outline_rounded,
                                text: employee.position!,
                              ),
                            if (employee.branch != null ||
                                employee.department != null)
                              _MetaRow(
                                icon: Icons.corporate_fare_rounded,
                                text: [
                                  if (employee.branch != null) employee.branch!,
                                  if (employee.department != null)
                                    employee.department!,
                                ].join(' · '),
                              ),
                            if (employee.email != null)
                              _MetaRow(
                                icon: Icons.mail_outline_rounded,
                                text: employee.email!,
                              ),
                          ],
                        ),
                      ),

                      // ── Overflow menu ────────────────────────────────────
                      // Delete used to sit on the card as a red button the
                      // same size as Edit — one mis-tap from destroying a
                      // record. It lives behind the menu now.
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppColors.grey400,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 18,
                        tooltip: '',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: AppColors.surface(context),
                        onSelected: (v) {
                          if (v == 'edit') {
                            context.push(
                              AppRoutes.adminEmployeeForm,
                              extra: employee,
                            );
                          } else {
                            _confirmDelete(context, ref, employee);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            height: 42,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 17,
                                  color: Color(0xFF0EA5E9),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.edit,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            height: 42,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.btnDelete,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(EmployeeData emp) {
    final parts = emp.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?';
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmployeeData employee,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteEmployeeTitle),
        content: Text(
          '${l10n.deleteEmployeeConfirmPrefix}${employee.name}${l10n.deleteEmployeeConfirmSuffix}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await HrRepository().deleteEmployee(employee.id);
                ref.invalidate(adminEmployeesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.employeeDeletedSuccess(employee.name)),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.errorPrefix}${e.toString()}'),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.btnDelete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.grey400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.grey600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
          ),
          items: items,
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.grey500,
          ),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;
  final AppLocalizations l10n;
  const _EmptyState({
    required this.hasFilters,
    required this.onClear,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters ? l10n.noEmployeesFound : l10n.noEmployeesYet,
            style: const TextStyle(
              color: AppColors.grey600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                l10n.clearFilters,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorState({required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadEmployees,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
