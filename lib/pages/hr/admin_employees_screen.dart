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

// ── Constants matching web ────────────────────────────────────────────────────
const _statusColors = {
  'active':     Color(0xFF16A34A),
  'inactive':   Color(0xFF6B7280),
  'terminated': Color(0xFFDC2626),
  'resigned':   Color(0xFFCA8A04),
  'on_leave':   Color(0xFF2563EB),
};

const _statusBg = {
  'active':     Color(0xFFDCFCE7),
  'inactive':   Color(0xFFF3F4F6),
  'terminated': Color(0xFFFEE2E2),
  'resigned':   Color(0xFFFEF9C3),
  'on_leave':   Color(0xFFDBEAFE),
};

const _typeLabels = {
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract':  'Contract',
  'intern':    'Intern',
};

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Employee Directory',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Filter Bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Search field
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey[400]),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _filters = _filters.copyWith(search: ''));
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter toggle button
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _showFilters ? AppColors.primary.withAlpha(20) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showFilters ? AppColors.primary : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 17,
                                color: _showFilters ? AppColors.primary : Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text('Filters',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _showFilters ? AppColors.primary : Colors.grey[700],
                                )),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('$_activeFilterCount',
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Filter Panel ─────────────────────────────────────────
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        // Row 1: Department + Branch
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<int?>(
                                label: 'Department',
                                value: _filters.departmentId,
                                hint: 'All Departments',
                                items: departmentsAsync.maybeWhen(
                                  data: (depts) => depts
                                      .map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name)))
                                      .toList(),
                                  orElse: () => [],
                                ),
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(departmentId: v)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FilterDropdown<int?>(
                                label: 'Branch',
                                value: _filters.branchId,
                                hint: 'All Branches',
                                items: branchesAsync.maybeWhen(
                                  data: (branches) => branches
                                      .map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name)))
                                      .toList(),
                                  orElse: () => [],
                                ),
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(branchId: v)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Row 2: Status + Type
                        Row(
                          children: [
                            Expanded(
                              child: _FilterDropdown<String>(
                                label: 'Status',
                                value: _filters.employmentStatus.isEmpty ? '' : _filters.employmentStatus,
                                hint: 'All Statuses',
                                items: [
                                  const DropdownMenuItem(value: '', child: Text('All Statuses')),
                                  ..._statusColors.keys.map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(fontSize: 12)))),
                                ],
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(employmentStatus: v ?? '')),
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
                                  ..._typeLabels.entries.map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value))),
                                ],
                                onChanged: (v) => setState(() =>
                                    _filters = _filters.copyWith(employmentType: v ?? '')),
                              ),
                            ),
                          ],
                        ),
                        if (_filters.hasActiveFilters) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _clearFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.clear_rounded, size: 14, color: Color(0xFFDC2626)),
                                  SizedBox(width: 6),
                                  Text('Clear all filters',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                                ],
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
          ),

          // ── Result count ─────────────────────────────────────────────────
          employeesAsync.maybeWhen(
            data: (employees) => Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              alignment: Alignment.centerLeft,
              child: Text(
                '${employees.length} employee${employees.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500]),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: employeesAsync.when(
              data: (employees) => employees.isEmpty
                  ? _EmptyState(hasFilters: _filters.hasActiveFilters, onClear: _clearFilters)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: employees.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _EmployeeCard(employee: employees[i]),
                    ),
              loading: () => const LoadingIndicator(message: 'Loading employees...'),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Failed to load employees', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(adminEmployeesProvider(_filters)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminEmployeeForm),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
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
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.6)),
        const SizedBox(height: 5),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Employee Card ─────────────────────────────────────────────────────────────
class _EmployeeCard extends ConsumerWidget {
  final EmployeeData employee;
  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = employee.employmentStatus ?? employee.status ?? 'active';
    final type = employee.employmentType ?? '';
    final statusColor = _statusColors[status] ?? const Color(0xFF6B7280);
    final statusBg = _statusBg[status] ?? const Color(0xFFF3F4F6);
    final typeLabel = _typeLabels[type] ?? type;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminEmployeeDetailScreen(employee: employee)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              // Top accent bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  gradient: LinearGradient(
                    colors: [statusColor.withAlpha(180), statusColor.withAlpha(80)],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withAlpha(20),
                      backgroundImage: employee.avatar != null ? NetworkImage(employee.avatar!) : null,
                      child: employee.avatar == null
                          ? Text(
                              _initials(employee),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badges row
                          Row(
                            children: [
                              Expanded(
                                child: Text(employee.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          if (employee.employeeId != null) ...[
                            const SizedBox(height: 2),
                            Text(employee.employeeId!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                          ],
                          const SizedBox(height: 6),

                          // Status + Type badges
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Badge(label: status.replaceAll('_', ' ').toUpperCase(),
                                  color: statusColor, bg: statusBg),
                              if (typeLabel.isNotEmpty)
                                _Badge(label: typeLabel,
                                    color: const Color(0xFF4B5563), bg: const Color(0xFFF3F4F6)),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Meta: position, branch/dept, email
                          if (employee.position != null)
                            _MetaRow(icon: Icons.work_outline_rounded, text: employee.position!),
                          if (employee.branch != null || employee.department != null)
                            _MetaRow(
                              icon: Icons.location_on_outlined,
                              text: [
                                if (employee.branch != null) employee.branch!,
                                if (employee.department != null) employee.department!,
                              ].join(' • '),
                            ),
                          if (employee.email != null)
                            _MetaRow(icon: Icons.mail_outline_rounded, text: employee.email!),
                        ],
                      ),
                    ),

                    // Action buttons column
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                          onPressed: () => context.push(AppRoutes.adminEmployeeForm, extra: employee),
                          tooltip: 'Edit',
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                          onPressed: () => _delete(context, ref),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
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
      return '${e.firstName![0]}${e.lastName![0]}'.toUpperCase();
    }
    return e.name.isNotEmpty ? e.name[0].toUpperCase() : '?';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(hrRepositoryProvider).deleteEmployee(employee.id);
        // Invalidate all cached filter variants
        ref.invalidate(adminEmployeesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${employee.name} deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to delete: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }
}

// ── Small Badge ───────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
    );
  }
}

// ── Meta Row ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.people_outline_rounded, size: 36, color: Color(0xFFD1D5DB)),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No employees match your filters' : 'No employees found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters ? 'Try adjusting your search or filters.' : 'Add your first employee to get started.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
