import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

// ─── Accent colors (work on white backgrounds) ───────────────────────────────
const _cardAccents = [
  AppColors.primary,
  AppColors.secondary,
  Color(0xFF10B981), // emerald
  Color(0xFF8B5CF6), // violet
  Color(0xFFF59E0B), // amber
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class AdminShiftsScreen extends ConsumerWidget {
  const AdminShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shifts & Calendars',
                  style: TextStyle(
                    color: AppColors.grey800,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Manage work schedules',
                  style: TextStyle(
                    color: AppColors.grey400,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: shiftsAsync.maybeWhen(
              data: (shifts) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${shifts.length} shifts',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) => shifts.isEmpty
            ? _EmptyState(onAdd: () => context.push(AppRoutes.adminShiftForm))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                itemCount: shifts.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ShiftCard(
                    shift: shifts[i],
                    colorIndex: i % _cardAccents.length,
                  ),
                ),
              ),
        loading: () => const LoadingIndicator(message: 'Loading shifts...'),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(shiftsProvider)),
      ),
      floatingActionButton: _GradientFAB(
        onPressed: () => context.push(AppRoutes.adminShiftForm),
      ),
    );
  }
}

// ─── Shift Card ──────────────────────────────────────────────────────────────
class _ShiftCard extends ConsumerWidget {
  final ShiftData shift;
  final int colorIndex;
  const _ShiftCard({required this.shift, required this.colorIndex});

  static const _dayAbbr = {
    'monday': 'Mo',
    'tuesday': 'Tu',
    'wednesday': 'We',
    'thursday': 'Th',
    'friday': 'Fr',
    'saturday': 'Sa',
    'sunday': 'Su',
  };
  static const _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  String _formatTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${parts[1]} $ampm';
  }

  IconData get _shiftIcon {
    if (shift.isOvernight) return Icons.nights_stay_rounded;
    if (!shift.isActive) return Icons.wb_cloudy_rounded;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _cardAccents[colorIndex];
    final schedule = shift.schedule;

    // Group consecutive working days with identical times into periods
    final periods = <Map<String, dynamic>>[];
    if (schedule != null) {
      String? currentStart, currentEnd, currentBreakStart, currentBreakEnd;
      final currentDays = <String>[];
      for (final day in _dayOrder) {
        final ds = schedule[day];
        if (ds != null && ds.isWorking) {
          final key = '${ds.start}|${ds.end}|${ds.breakStart}|${ds.breakEnd}';
          final newKey = '$currentStart|$currentEnd|$currentBreakStart|$currentBreakEnd';
          if (currentStart == null || key != newKey) {
            if (currentDays.isNotEmpty) {
              periods.add({
                'days': List<String>.from(currentDays),
                'start': _formatTime(currentStart!),
                'end': _formatTime(currentEnd!),
                'breakStart': currentBreakStart != null ? _formatTime(currentBreakStart) : null,
                'breakEnd': currentBreakEnd != null ? _formatTime(currentBreakEnd) : null,
              });
            }
            currentStart = ds.start;
            currentEnd = ds.end;
            currentBreakStart = ds.breakStart;
            currentBreakEnd = ds.breakEnd;
            currentDays.clear();
          }
          currentDays.add(day);
        } else {
          if (currentDays.isNotEmpty) {
            periods.add({
              'days': List<String>.from(currentDays),
              'start': _formatTime(currentStart!),
              'end': _formatTime(currentEnd!),
              'breakStart': currentBreakStart != null ? _formatTime(currentBreakStart) : null,
              'breakEnd': currentBreakEnd != null ? _formatTime(currentBreakEnd) : null,
            });
          }
          currentStart = null;
          currentEnd = null;
          currentBreakStart = null;
          currentBreakEnd = null;
          currentDays.clear();
        }
      }
      if (currentDays.isNotEmpty) {
        periods.add({
          'days': List<String>.from(currentDays),
          'start': _formatTime(currentStart!),
          'end': _formatTime(currentEnd!),
          'breakStart': currentBreakStart != null ? _formatTime(currentBreakStart) : null,
          'breakEnd': currentBreakEnd != null ? _formatTime(currentBreakEnd) : null,
        });
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent bar ──────────────────────────────────────
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // ── Card content ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shift icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_shiftIcon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 10),

                        // Name + badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      shift.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.grey800,
                                      ),
                                    ),
                                  ),
                                  if (shift.code != null && shift.code!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: accent.withAlpha(40)),
                                      ),
                                      child: Text(
                                        shift.code!,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: accent),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _Badge(
                                    label: shift.isActive ? 'ACTIVE' : 'INACTIVE',
                                    color: shift.isActive
                                        ? AppColors.success
                                        : AppColors.grey500,
                                    bg: shift.isActive
                                        ? const Color(0xFFDCFCE7)
                                        : AppColors.grey100,
                                  ),
                                  if (shift.isOvernight) ...[
                                    const SizedBox(width: 5),
                                    const _Badge(
                                      label: 'OVERNIGHT',
                                      color: Color(0xFF4F46E5),
                                      bg: Color(0xFFEEF2FF),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Column(
                          children: [
                            _IconBtn(
                              icon: Icons.edit_rounded,
                              color: AppColors.secondary,
                              bg: AppColors.secondaryLight,
                              onTap: () =>
                                  context.push(AppRoutes.adminShiftForm, extra: shift),
                            ),
                            const SizedBox(height: 6),
                            _IconBtn(
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

                  // ── Divider ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Divider(height: 1, color: AppColors.grey100),
                  ),

                  // ── Schedule periods ─────────────────────────────────
                  if (periods.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: periods.map((p) {
                          final days = p['days'] as List<String>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Day pill chips
                                    Wrap(
                                      spacing: 3,
                                      children: days.map((d) {
                                        final abbr = _dayAbbr[d] ?? d.substring(0, 2);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(15),
                                            borderRadius: BorderRadius.circular(5),
                                            border:
                                                Border.all(color: accent.withAlpha(35)),
                                          ),
                                          child: Text(
                                            abbr,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const Spacer(),
                                    // Time range
                                    Row(
                                      children: [
                                        Icon(Icons.schedule_rounded,
                                            size: 11, color: AppColors.grey500),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${p['start']} – ${p['end']}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.grey700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (p['breakStart'] != null) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.coffee_rounded,
                                          size: 10, color: AppColors.grey400),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Break ${p['breakStart']} – ${p['breakEnd']}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.grey500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // ── Stats + Assign row ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Row(
                      children: [
                        _StatPill(
                            icon: Icons.timer_outlined,
                            label: '${shift.gracePeriod}m grace',
                            color: accent),
                        const SizedBox(width: 8),
                        _StatPill(
                            icon: Icons.more_time_rounded,
                            label: 'OT≥${shift.overtimeThreshold}m',
                            color: accent),
                        const Spacer(),
                        _StatPill(
                          icon: Icons.people_alt_rounded,
                          label: '${shift.employeesCount ?? 0}',
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAssignSheet(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_add_alt_1_rounded,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 5),
                                Text(
                                  'Assign',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
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

              const Text(
                "Delete Shift?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: "Are you sure you want to delete\n",
                    ),
                    TextSpan(
                      text: '"${shift.name}"',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text:
                          "?\n\nThis action cannot be undone.",
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
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
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
                      label: const Text("Delete"),
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
      await ref.read(adminOpsRepositoryProvider).deleteShift(shift.id);

      ref.invalidate(shiftsProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${shift.name} deleted successfully"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete: $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

  void _showAssignSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) =>
            _AssignShiftSheet(shift: shift, scrollController: controller),
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Assign Bottom Sheet ──────────────────────────────────────────────────────
class _AssignShiftSheet extends ConsumerStatefulWidget {
  final ShiftData shift;
  final ScrollController scrollController;
  const _AssignShiftSheet({required this.shift, required this.scrollController});

  @override
  ConsumerState<_AssignShiftSheet> createState() => _AssignShiftSheetState();
}

final shiftAssignmentsProvider = FutureProvider.autoDispose<List<ShiftAssignmentData>>((ref) async {
  return ref.read(adminOpsRepositoryProvider).getShiftAssignments();
});

class _AssignShiftSheetState extends ConsumerState<_AssignShiftSheet> {
  final Set<int> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _initializedAssignments = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider);

    final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;

    final Map<int, ShiftAssignmentData> activeAssignments = {};
    if (assignmentsAsync.value != null) {
      for (final a in assignmentsAsync.value!) {
        if (a.endDate == null || a.endDate!.isEmpty) {
          activeAssignments[a.employeeId] = a;
        }
      }
      if (!_initializedAssignments && employeesAsync.value != null) {
        _initializedAssignments = true;
        final validEmpIds = employeesAsync.value!
            .where((e) => e.employmentStatus != 'terminated' && (activeBranchId == null || e.branchId == null || e.branchId == activeBranchId))
            .map((e) => e.id)
            .toSet();

        for (final a in assignmentsAsync.value!) {
          if (a.shiftId == widget.shift.id && (a.endDate == null || a.endDate!.isEmpty)) {
            if (validEmpIds.contains(a.employeeId)) {
              _selectedIds.add(a.employeeId);
            }
          }
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assign Employees',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.grey800)),
                      Text(
                        '${widget.shift.name} · ${_selectedIds.length} selected',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.grey500, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search employees...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.grey400),
                  prefixIcon:
                      Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Employee list
          Expanded(
            child: employeesAsync.when(
              data: (allEmployees) {
                var filtered = allEmployees.where((e) {
                  if (e.employmentStatus == 'terminated') return false;
                  if (activeBranchId != null && e.branchId != null && e.branchId != activeBranchId) return false;
                  return true;
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((e) =>
                          e.name.toLowerCase().contains(_searchQuery) ||
                          (e.employeeId ?? '').toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No employees found',
                        style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                  );
                }

                final allFilteredSelected =
                    filtered.every((e) => _selectedIds.contains(e.id));

                return Column(
                  children: [
                    // Select All row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (allFilteredSelected) {
                              for (final e in filtered) {
                                _selectedIds.remove(e.id);
                              }
                            } else {
                              for (final e in filtered) {
                                _selectedIds.add(e.id);
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(
                                allFilteredSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 18,
                                color: allFilteredSelected
                                    ? AppColors.primary
                                    : AppColors.grey400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                allFilteredSelected ? 'Deselect All' : 'Select All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: allFilteredSelected
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                ),
                              ),
                              const Spacer(),
                              Text('${filtered.length} employees',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.grey400)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // List
                    Expanded(
                      child: ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final emp = filtered[i];
                          final isSelected = _selectedIds.contains(emp.id);
                          final activeAssign = activeAssignments[emp.id];
                          final isThisShift = activeAssign?.shiftId == widget.shift.id;
                          final isOtherShift = activeAssign != null && !isThisShift;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(emp.id);
                                } else {
                                  _selectedIds.add(emp.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary.withAlpha(60)
                                      : AppColors.grey100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emp.name.isNotEmpty
                                            ? emp.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.grey500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                emp.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.grey800,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isThisShift) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.success.withAlpha(60)),
                                                ),
                                                child: const Text(
                                                  'Assigned',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ] else if (isOtherShift) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.info.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.info.withAlpha(60)),
                                                ),
                                                child: Text(
                                                  activeAssign.shiftName ?? 'Other Shift',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.info,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (emp.employeeId != null)
                                          Text(emp.employeeId!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.grey400)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey300,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(
                child: Text('Error loading employees',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.grey100)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedIds.isEmpty || _isLoading ? null : _assign,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selectedIds.isEmpty
                                ? 'Assign'
                                : 'Assign ${_selectedIds.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _assign() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      int successCount = 0;
      int failCount = 0;
      for (final empId in _selectedIds) {
        try {
          await repo.assignShift(widget.shift.id, empId);
          successCount++;
        } catch (_) {
          failCount++;
        }
      }
      ref.invalidate(shiftsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$successCount assigned${failCount > 0 ? ', $failCount failed' : ''}'),
            backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Empty & Error states ─────────────────────────────────────────────────────
// ─── Custom FAB ───────────────────────────────────────────────────────────────
class _GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _GradientFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(70),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'New Shift',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty & Error states ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

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
              child: const Icon(Icons.schedule_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Shifts Yet',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.grey800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first shift to start managing work schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Shift',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppColors.danger, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load shifts',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.grey700)),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.',
              style: TextStyle(color: AppColors.grey500, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
