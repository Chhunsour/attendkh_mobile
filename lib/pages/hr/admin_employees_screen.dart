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
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

// ── Status config ────────────────────────────────────────────────────────────
const _statusConfig = {
  'active':     _StatusCfg(AppColors.success, AppColors.successLight, Icons.check_circle_rounded),
  'inactive':   _StatusCfg(AppColors.grey600, AppColors.grey100, Icons.pause_circle_rounded),
  'terminated': _StatusCfg(AppColors.danger, AppColors.dangerLight, Icons.cancel_rounded),
  'resigned':   _StatusCfg(AppColors.warning, AppColors.warningLight, Icons.logout_rounded),
  'on_leave':   _StatusCfg(AppColors.primary, AppColors.primaryLight, Icons.beach_access_rounded),
};

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.color, this.bg, this.icon);
}

String _getLocalizedType(String type, AppLocalizations l10n) {
  switch (type) {
    case 'full_time': return l10n.fullTime;
    case 'part_time': return l10n.partTime;
    case 'contract': return l10n.contract;
    case 'intern': return l10n.intern;
    default: return type;
  }
}


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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // ── App Bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.employeeDirectory,
                  style: const TextStyle(color: AppColors.grey800, fontSize: 17, fontWeight: FontWeight.w700, height: 1.2),
                ),
                Text(
                  l10n.manageYourWorkforce,
                  style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w400),
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
                  l10n.peopleCount(employees.length),
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
            color: AppColors.surfaceLight,
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
                            hintText: l10n.searchEmployeesHint,
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
                              l10n.filter,
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
                                label: l10n.department,
                                value: _filters.departmentId,
                                hint: l10n.allDepartments,
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
                                label: l10n.branch,
                                value: _filters.branchId,
                                hint: l10n.allBranches,
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
                                label: l10n.status,
                                value: _filters.employmentStatus.isEmpty ? '' : _filters.employmentStatus,
                                hint: l10n.allStatuses,
                                items: [
                                  DropdownMenuItem(value: '', child: Text(l10n.allStatuses)),
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
                                label: l10n.type,
                                value: _filters.employmentType.isEmpty ? '' : _filters.employmentType,
                                hint: l10n.allTypes,
                                items: [
                                  DropdownMenuItem(value: '', child: Text(l10n.allTypes)),
                                  ...['full_time', 'part_time', 'contract', 'intern'].map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(_getLocalizedType(type, l10n)),
                                    ),
                                  ),
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
                              label: Text(l10n.clearAllFilters),
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
                    l10n.employeeCount(employees.length, employees.length != 1 ? 's' : ''),
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
                      child: Text(
                        l10n.filtered,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                  ? _EmptyState(hasFilters: _filters.hasActiveFilters, onClear: _clearFilters, l10n: l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: employees.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EmployeeCard(employee: employees[i], colorIndex: i % _avatarColors.length, l10n: l10n),
                      ),
                    ),
              loading: () => LoadingIndicator(message: l10n.loadingEmployees),
              error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(adminEmployeesProvider(_filters)), l10n: l10n),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addEmployee,
                    style: const TextStyle(
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
  final AppLocalizations l10n;
  const _EmployeeCard({required this.employee, required this.colorIndex, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = employee.employmentStatus ?? employee.status ?? 'active';
    final type = employee.employmentType ?? '';
    final cfg = _statusConfig[status] ?? const _StatusCfg(Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.help_outline_rounded);
    final typeLabel = _getLocalizedType(type, l10n);
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
                              ? ClipOval(
                                  child: Image.network(
                                    employee.avatar!.startsWith('http') 
                                        ? employee.avatar! 
                                        : '${DioClient.storageUrl}/${employee.avatar!.startsWith('/') ? employee.avatar!.substring(1) : employee.avatar!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Center(
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
                                )
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
                          onTap: () => _delete(context, ref, l10n),
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

  Future<void> _delete(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                l10n.deleteEmployeeTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.grey800,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: l10n.deleteEmployeeConfirmPrefix,
                    ),
                    TextSpan(
                      text: employee.name,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: l10n.deleteEmployeeConfirmSuffix,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(
                          color: Colors.grey,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.delete),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirm == true) {
    try {
      await ref.read(hrRepositoryProvider).deleteEmployee(employee.id);

      ref.invalidate(adminEmployeesProvider);
      ref.invalidate(allEmployeesProvider);
      ref.invalidate(dashboardStatsProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.employeeDeletedSuccess(employee.name)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedMsg(e.toString())),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  final AppLocalizations l10n;
  const _EmptyState({required this.hasFilters, required this.onClear, required this.l10n});

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
              hasFilters ? l10n.noResultsFound : l10n.noEmployeesYet,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.grey800),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? l10n.adjustFiltersHint
                  : l10n.startBuildingTeamHint,
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
                label: Text(l10n.clearFilters, style: const TextStyle(fontWeight: FontWeight.w600)),
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
  final AppLocalizations l10n;
  const _ErrorState({required this.onRetry, required this.l10n});

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
          Text(l10n.failedToLoadEmployees, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey700)),
          const SizedBox(height: 8),
          Text(l10n.checkConnectionTryAgain, style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
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
            label: Text(l10n.tryAgain, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
