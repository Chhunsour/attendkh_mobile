import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_detail_screen.dart';

// ── Status config ────────────────────────────────────────────────────────────
const _statusConfig = {
  'active':     _StatusCfg(Color(0xFF16A34A), Color(0xFFDCFCE7), Icons.check_circle_rounded),
  'inactive':   _StatusCfg(Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.pause_circle_rounded),
  'terminated': _StatusCfg(Color(0xFFDC2626), Color(0xFFFEE2E2), Icons.cancel_rounded),
  'resigned':   _StatusCfg(Color(0xFFCA8A04), Color(0xFFFEF9C3), Icons.logout_rounded),
  'on_leave':   _StatusCfg(Color(0xFF2563EB), Color(0xFFDBEAFE), Icons.beach_access_rounded),
};

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.color, this.bg, this.icon);
}

const _typeLabels = {
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract':  'Contract',
  'intern':    'Intern',
};

// Avatar background colors (cycling)
const _avatarColors = [
  Color(0xFFFFF7ED), // orange
  Color(0xFFEFF6FF), // blue
  Color(0xFFF0FDF4), // green
  Color(0xFFFDF4FF), // purple
  Color(0xFFFFFBEB), // amber
];
const _avatarFgColors = [
  AppColors.primary,
  AppColors.secondary,
  Color(0xFF16A34A),
  Color(0xFF7C3AED),
  Color(0xFFD97706),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  EmployeeFilters _filters = const EmployeeFilters();
  bool _showFilters = false;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _filters = _filters.copyWith(search: val));
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // ── App Bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey100),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Directory',
                  style: TextStyle(color: AppColors.grey800, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2),
                ),
                Text(
                  'Manage your workforce',
                  style: TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: employeesAsync.maybeWhen(
              data: (employees) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${employees.length} people',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search + Filter Bar ────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 14, color: AppColors.grey800),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, ID...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.grey400),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      setState(() => _filters = _filters.copyWith(search: ''));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: AppColors.grey200, shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.grey600),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter button
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _showFilters ? AppColors.primaryLight : AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _showFilters ? AppColors.primary : AppColors.grey200,
                            width: _showFilters ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 18, color: _showFilters ? AppColors.primary : AppColors.grey500),
                            const SizedBox(width: 6),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showFilters ? AppColors.primary : AppColors.grey600,
                              ),
                            ),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Filter Panel ──────────────────────────────────────────
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<int?>(
                                label: 'Department',
                                value: _filters.departmentId,
                                hint: 'All Departments',
                                items: departmentsAsync.maybeWhen(
                                  data: (depts) => depts.map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name))).toList(),
                                  orElse: () => [],
                                ),
                                onChanged: (v) => setState(() => _filters = _filters.copyWith(departmentId: v)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown<int?>(
                                label: 'Branch',
                                value: _filters.branchId,
                                hint: 'All Branches',
                                items: branchesAsync.maybeWhen(
                                  data: (branches) => branches.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name))).toList(),
                                  orElse: () => [],
                                ),
                                onChanged: (v) => setState(() => _filters = _filters.copyWith(branchId: v)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<String>(
                                label: 'Status',
                                value: _filters.employmentStatus.isEmpty ? '' : _filters.employmentStatus,
                                hint: 'All Statuses',
                                items: [
                                  const DropdownMenuItem(value: '', child: Text('All Statuses')),
                                  ..._statusConfig.keys.map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                                      )),
                                ],
                                onChanged: (v) => setState(() => _filters = _filters.copyWith(employmentStatus: v ?? '')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown<String>(
                                label: 'Type',
                                value: _filters.employmentType.isEmpty ? '' : _filters.employmentType,
                                hint: 'All Types',
                                items: [
                                  const DropdownMenuItem(value: '', child: Text('All Types')),
                                  ..._typeLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                                ],
                                onChanged: (v) => setState(() => _filters = _filters.copyWith(employmentType: v ?? '')),
                              ),
                            ),
                          ],
                        ),
                        if (_filters.hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _clearFilters,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              icon: const Icon(Icons.clear_rounded, size: 15),
                              label: const Text('Clear all filters'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Result count bar ─────────────────────────────────────────────
          employeesAsync.maybeWhen(
            data: (employees) => Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${employees.length} employee${employees.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500),
                  ),
                  if (_filters.hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Filtered',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          // ── Employee List ────────────────────────────────────────────────
          Expanded(
            child: employeesAsync.when(
              data: (employees) => employees.isEmpty
                  ? _EmptyState(hasFilters: _filters.hasActiveFilters, onClear: _clearFilters)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: employees.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EmployeeCard(employee: employees[i], colorIndex: i % _avatarColors.length),
                      ),
                    ),
              loading: () => const LoadingIndicator(message: 'Loading employees...'),
              error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(adminEmployeesProvider(_filters))),
            ),
          ),
        ],
      ),

      floatingActionButton: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(100),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(AppRoutes.adminEmployeeForm),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Employee Card ─────────────────────────────────────────────────────────────
class _EmployeeCard extends ConsumerWidget {
  final EmployeeData employee;
  final int colorIndex;
  const _EmployeeCard({required this.employee, required this.colorIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = employee.employmentStatus ?? employee.status ?? 'active';
    final type = employee.employmentType ?? '';
    final cfg = _statusConfig[status] ?? const _StatusCfg(Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.help_outline_rounded);
    final typeLabel = _typeLabels[type] ?? type;
    final avatarBg = _avatarColors[colorIndex];
    final avatarFg = _avatarFgColors[colorIndex];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminEmployeeDetailScreen(employee: employee)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: cfg.color.withAlpha(18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ───────────────────────────────────────────
                    Stack(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: employee.avatar != null ? avatarBg : avatarBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: cfg.color.withAlpha(60), width: 2),
                          ),
                          child: employee.avatar != null
                              ? ClipOval(child: Image.network(employee.avatar!, fit: BoxFit.cover))
                              : Center(
                                  child: Text(
                                    _initials(employee),
                                    style: TextStyle(
                                      color: avatarFg,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                        // Status dot
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cfg.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // ── Info ──────────────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.grey800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Employee ID
                          if (employee.employeeId != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              employee.employeeId!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Status + type badges
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              // Status badge with icon
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cfg.bg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cfg.color.withAlpha(60)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cfg.icon, size: 10, color: cfg.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: cfg.color,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (typeLabel.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.grey600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Meta info
                          if (employee.position != null)
                            _MetaRow(icon: Icons.work_outline_rounded, text: employee.position!),
                          if (employee.branch != null || employee.department != null)
                            _MetaRow(
                              icon: Icons.corporate_fare_rounded,
                              text: [
                                if (employee.branch != null) employee.branch!,
                                if (employee.department != null) employee.department!,
                              ].join(' · '),
                            ),
                          if (employee.email != null)
                            _MetaRow(icon: Icons.mail_outline_rounded, text: employee.email!),
                        ],
                      ),
                    ),

                    // ── Action column ────────────────────────────────────
                    Column(
                      children: [
                        _ActionBtn(
                          icon: Icons.edit_rounded,
                          color: AppColors.secondary,
                          bg: AppColors.secondaryLight,
                          onTap: () => context.push(AppRoutes.adminEmployeeForm, extra: employee),
                        ),
                        const SizedBox(height: 6),
                        _ActionBtn(
                          icon: Icons.delete_rounded,
                          color: AppColors.danger,
                          bg: AppColors.dangerLight,
                          onTap: () => _delete(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bottom row: quick contact chips ───────────────────────
              if (employee.phone != null || employee.email != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        height: 1,
                        width: 20,
                        color: AppColors.grey100,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.grey100),
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

  String _initials(EmployeeData e) {
    if (e.firstName != null && e.lastName != null) {
      final f = e.firstName!.trim();
      final l = e.lastName!.trim();
      return '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'.toUpperCase();
    }
    final parts = e.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return e.name.isNotEmpty ? e.name[0].toUpperCase() : '?';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete Employee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete ${employee.name}? This cannot be undone.',
          style: const TextStyle(color: AppColors.grey600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(hrRepositoryProvider).deleteEmployee(employee.id);
        ref.invalidate(adminEmployeesProvider);
        ref.invalidate(allEmployeesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ ${employee.name} deleted'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
      );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.grey400),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey400, letterSpacing: 0.6),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.grey400)),
              style: const TextStyle(fontSize: 13, color: AppColors.grey800),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.grey500),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.people_alt_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No results found' : 'No Employees Yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.grey800),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters to find what you\'re looking for.'
                  : 'Start building your team by adding your first employee.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.grey500),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: Size.zero,
                ),
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Filters', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.danger),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load employees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey700)),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
