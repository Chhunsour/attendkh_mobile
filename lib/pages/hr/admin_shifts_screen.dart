import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
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
class AdminShiftsScreen extends ConsumerStatefulWidget {
  const AdminShiftsScreen({super.key});

  @override
  ConsumerState<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends ConsumerState<AdminShiftsScreen> with SingleTickerProviderStateMixin {
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

  void _openAssignModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) =>
            _AssignShiftSheet(shift: null, scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shiftsAndCalendars,
                  style: const TextStyle(
                    color: AppColors.grey800,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Text(
                  l10n.manageWorkSchedules,
                  style: const TextStyle(
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
                  l10n.shiftsCount(shifts.length.toString()),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Schedules'),
            Tab(text: 'Shift Assignments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Schedules
          shiftsAsync.when(
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
            loading: () => LoadingIndicator(message: l10n.loadingShifts),
            error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(shiftsProvider)),
          ),

          // Tab 2: Assignments
          const _ShiftAssignmentsTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return _GradientFAB(
              onPressed: () => context.push(AppRoutes.adminShiftForm),
            );
          } else {
            return _GradientFAB(
              onPressed: () => _openAssignModal(context),
              label: 'Assign Shift',
              icon: Icons.person_add_alt_1_rounded,
            );
          }
        },
      ),
    );
  }
}

// ─── Shift Card ──────────────────────────────────────────────────────────────
class _ShiftCard extends ConsumerWidget {
  final ShiftData shift;
  final int colorIndex;
  const _ShiftCard({required this.shift, required this.colorIndex});


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
    final l10n = AppLocalizations.of(context)!;
    final dayAbbr = {
      'monday': l10n.dayMo,
      'tuesday': l10n.dayTu,
      'wednesday': l10n.dayWe,
      'thursday': l10n.dayTh,
      'friday': l10n.dayFr,
      'saturday': l10n.daySa,
      'sunday': l10n.daySu,
    };
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
                                    label: shift.isActive ? l10n.activeShiftBadge : l10n.inactiveShiftBadge,
                                    color: shift.isActive
                                        ? AppColors.success
                                        : AppColors.grey500,
                                    bg: shift.isActive
                                        ? const Color(0xFFDCFCE7)
                                        : AppColors.grey100,
                                  ),
                                  if (shift.isOvernight) ...[
                                    const SizedBox(width: 5),
                                    _Badge(
                                      label: l10n.overnightBadge,
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
                                        final abbr = dayAbbr[d] ?? d.substring(0, 2);
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
                                        l10n.breakTimeRange(p['breakStart'].toString(), p['breakEnd'].toString()),
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
                          icon: Icons.people_alt_rounded,
                          label: '${shift.employeesCount ?? 0}',
                          color: AppColors.grey500,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showAssignSheet(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.assign,
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
  final l10n = AppLocalizations.of(context)!;
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
                l10n.deleteShiftTitle,
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
                    color: AppColors.grey800,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: l10n.deleteShiftConfirmPrefix,
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
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
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
      await ref.read(adminOpsRepositoryProvider).deleteShift(shift.id);

      ref.invalidate(shiftsProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shiftDeletedSuccess(shift.name)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shiftDeleteFailed(e.toString())),
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
  final ShiftData? shift;
  final ScrollController scrollController;
  const _AssignShiftSheet({this.shift, required this.scrollController});

  @override
  ConsumerState<_AssignShiftSheet> createState() => _AssignShiftSheetState();
}

final shiftAssignmentsProvider = FutureProvider.autoDispose<List<ShiftAssignmentData>>((ref) async {
  return ref.read(adminOpsRepositoryProvider).getShiftAssignments();
});

class _AssignShiftSheetState extends ConsumerState<_AssignShiftSheet> {
  final Set<int> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _effectiveDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final TextEditingController _endDateCtrl = TextEditingController();
  int? _selectedShiftId;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _initializedAssignments = false;

  @override
  void initState() {
    super.initState();
    _selectedShiftId = widget.shift?.id;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _effectiveDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employeesAsync = ref.watch(allEmployeesProvider);
    final shiftsAsync = ref.watch(shiftsProvider);
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider);

    final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;

    final Map<int, ShiftAssignmentData> activeAssignments = {};
    if (assignmentsAsync.value != null) {
      for (final a in assignmentsAsync.value!) {
        if (a.endDate == null || a.endDate!.isEmpty) {
          activeAssignments[a.employeeId] = a;
        }
      }
      if (!_initializedAssignments && employeesAsync.value != null && widget.shift != null) {
        _initializedAssignments = true;
        final validEmpIds = employeesAsync.value!
            .where((e) => e.employmentStatus != 'terminated' && (activeBranchId == null || e.branchId == null || e.branchId == activeBranchId))
            .map((e) => e.id)
            .toSet();

        for (final a in assignmentsAsync.value!) {
          if (a.shiftId == widget.shift!.id && (a.endDate == null || a.endDate!.isEmpty)) {
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
                      Text(l10n.assignEmployeesTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.grey800)),
                      Text(
                        l10n.assignEmployeesSubtitle(widget.shift?.name ?? 'Shift', _selectedIds.length.toString()),
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

          const SizedBox(height: 12),

          if (widget.shift == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: shiftsAsync.when(
                data: (shifts) => DropdownButtonFormField<int>(
                  initialValue: _selectedShiftId,
                  decoration: InputDecoration(
                    labelText: 'Shift *',
                    hintText: 'Select shift',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedShiftId = val;
                      _selectedIds.clear();
                      if (val != null && assignmentsAsync.value != null) {
                        for (final a in assignmentsAsync.value!) {
                          if (a.shiftId == val && (a.endDate == null || a.endDate!.isEmpty)) {
                            _selectedIds.add(a.employeeId);
                          }
                        }
                      }
                    });
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Effective Date & End Date fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _effectiveDateCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Effective Date *',
                      hintText: 'YYYY-MM-DD',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _endDateCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'End Date (Optional)',
                      hintText: 'YYYY-MM-DD',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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
                decoration: InputDecoration(
                  hintText: l10n.searchEmployeesHint,
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.grey400),
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                                allFilteredSelected ? l10n.deselectAll : l10n.selectAll,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: allFilteredSelected
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                ),
                              ),
                              const Spacer(),
                              Text(l10n.employeesCountLabel(filtered.length.toString()),
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
                          final isThisShift = widget.shift != null && activeAssign?.shiftId == widget.shift!.id;
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
                                                child: Text(
                                                  l10n.assignedBadge,
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
                                                  activeAssign.shiftName ?? l10n.otherShiftBadge,
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
                    child: Text(l10n.cancel,
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
                            _selectedIds.isEmpty ? l10n.assign : l10n.assignCount(_selectedIds.length.toString()),
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
    final l10n = AppLocalizations.of(context)!;
    final targetShiftId = _selectedShiftId ?? widget.shift?.id;
    if (targetShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift schedule'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      int successCount = 0;
      int failCount = 0;
      for (final empId in _selectedIds) {
        try {
          await repo.assignShift(
            targetShiftId,
            empId,
            effectiveDate: _effectiveDateCtrl.text.trim(),
            endDate: _endDateCtrl.text.trim(),
          );
          successCount++;
        } catch (_) {
          failCount++;
        }
      }
      ref.invalidate(shiftsProvider);
      ref.invalidate(shiftAssignmentsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                failCount > 0 ? l10n.assignSuccessWithFail(successCount.toString(), failCount.toString()) : l10n.assignSuccess(successCount.toString())),
            backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.assignFailedError(e.toString())), backgroundColor: AppColors.danger),
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
  final String? label;
  final IconData icon;

  const _GradientFAB({
    required this.onPressed,
    this.label,
    this.icon = Icons.add_rounded,
  });

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
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label ?? AppLocalizations.of(context)!.newShift,
              style: const TextStyle(
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
            Text(
              AppLocalizations.of(context)!.noShiftsYet,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.grey800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createFirstShiftDesc,
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
              label: Text(AppLocalizations.of(context)!.createFirstShiftBtn,
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
          Text(AppLocalizations.of(context)!.failedToLoadShifts,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.grey700)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.checkConnectionRetry,
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
            label: Text(AppLocalizations.of(context)!.tryAgain,
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ShiftAssignmentsTab extends ConsumerStatefulWidget {
  const _ShiftAssignmentsTab();

  @override
  ConsumerState<_ShiftAssignmentsTab> createState() => _ShiftAssignmentsTabState();
}

class _ShiftAssignmentsTabState extends ConsumerState<_ShiftAssignmentsTab> {
  String _searchQuery = '';

  Widget _buildScheduleBadges(Map<String, dynamic>? schedule) {
    if (schedule == null || schedule.isEmpty) return const SizedBox.shrink();
    final daysMap = [
      {'key': 'monday', 'short': 'Mon'},
      {'key': 'tuesday', 'short': 'Tue'},
      {'key': 'wednesday', 'short': 'Wed'},
      {'key': 'thursday', 'short': 'Thu'},
      {'key': 'friday', 'short': 'Fri'},
      {'key': 'saturday', 'short': 'Sat'},
      {'key': 'sunday', 'short': 'Sun'},
    ];

    final List<Widget> badges = [];
    for (final d in daysMap) {
      final sched = schedule[d['key']];
      if (sched is Map && (sched['is_working'] == true || sched['is_working'] == 1)) {
        final start = _fmtTime(sched['start']?.toString());
        final end = _fmtTime(sched['end']?.toString());
        badges.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Text(
              '${d['short']}: $start - $end',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey700),
            ),
          ),
        );
      }
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }

  String _fmtTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final h = int.tryParse(parts[0]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${parts[1]} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        final filtered = assignments.where((a) {
          final name = (a.employeeName ?? '').toLowerCase();
          final code = (a.employeeCode ?? '').toLowerCase();
          final shift = (a.shiftName ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();
          return name.contains(q) || code.contains(q) || shift.contains(q);
        }).toList();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceLight,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search employee or shift assignment…',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grey500),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.grey200),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No shift assignments found', style: TextStyle(color: AppColors.grey400)),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(shiftAssignmentsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Avatar / Photo
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(22),
                                        image: (item.employeePhoto != null && item.employeePhoto!.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(item.employeePhoto!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (item.employeePhoto == null || item.employeePhoto!.isEmpty)
                                          ? Center(
                                              child: Text(
                                                (item.employeeName != null && item.employeeName!.isNotEmpty)
                                                    ? item.employeeName![0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.employeeName ?? 'Employee #${item.employeeId}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey800),
                                          ),
                                          Row(
                                            children: [
                                              if (item.employeeCode != null && item.employeeCode!.isNotEmpty)
                                                Text(item.employeeCode!, style: const TextStyle(fontSize: 11, color: AppColors.grey400, fontFamily: 'monospace')),
                                              if (item.employeePosition != null && item.employeePosition!.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                const Text('•', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    item.employeePosition!,
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                      onPressed: () async {
                                        try {
                                          await ref.read(adminOpsRepositoryProvider).deleteShiftAssignment(item.id);
                                          ref.invalidate(shiftAssignmentsProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Shift assignment deleted.'), backgroundColor: AppColors.success),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item.shiftName ?? 'Shift #${item.shiftId}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.grey800),
                                          ),
                                          Text(
                                            '${item.effectiveDate ?? '—'} ${item.endDate != null && item.endDate!.isNotEmpty ? '→ ${item.endDate}' : '(Indefinite)'}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                                          ),
                                        ],
                                      ),
                                      if (item.shiftSchedule != null) ...[
                                        const SizedBox(height: 6),
                                        _buildScheduleBadges(item.shiftSchedule),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading shift assignments…'),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(shiftAssignmentsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}

class _AssignShiftModal extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AssignShiftModal({required this.onSaved});

  @override
  ConsumerState<_AssignShiftModal> createState() => _AssignShiftModalState();
}

class _AssignShiftModalState extends ConsumerState<_AssignShiftModal> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdCtrl = TextEditingController();
  final _effectiveDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _endDateCtrl = TextEditingController();
  int? _selectedShiftId;
  bool _isSaving = false;

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    _effectiveDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedShiftId == null) {
      if (_selectedShiftId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a shift schedule')));
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final empId = int.parse(_employeeIdCtrl.text.trim());
      await ref.read(adminOpsRepositoryProvider).assignShift(
        _selectedShiftId!,
        empId,
        effectiveDate: _effectiveDateCtrl.text.trim(),
        endDate: _endDateCtrl.text.trim(),
      );
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift assigned successfully.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assign Shift to Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              shiftsAsync.when(
                data: (shifts) => DropdownButtonFormField<int>(
                  initialValue: _selectedShiftId,
                  decoration: const InputDecoration(labelText: 'Select Shift Schedule *', border: OutlineInputBorder()),
                  items: shifts.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => _selectedShiftId = val),
                  validator: (val) => val == null ? 'Please select a shift' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Text('Failed to load shift options'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Employee ID *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter employee ID' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _effectiveDateCtrl,
                decoration: const InputDecoration(labelText: 'Effective Date * (YYYY-MM-DD)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter effective date' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endDateCtrl,
                decoration: const InputDecoration(labelText: 'End Date (Optional) (YYYY-MM-DD)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Assign Shift', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
