import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/components/loading_indicator.dart';

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

class _AdminShiftsScreenState extends ConsumerState<AdminShiftsScreen>
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.shiftsAndCalendars,
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
            onPressed: () {
              ref.invalidate(shiftsProvider);
            },
          ),
          shiftsAsync.maybeWhen(
            data: (shifts) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${shifts.length} shifts',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
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
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFF8B5CF6),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Schedules'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Shift Assignments'),
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
        children: [
          // Tab 1: Schedules
          shiftsAsync.when(
            data: (shifts) => shifts.isEmpty
                ? _EmptyState(
                    onAdd: () => context.push(AppRoutes.adminShiftForm),
                  )
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
            error: (e, _) =>
                _ErrorState(onRetry: () => ref.invalidate(shiftsProvider)),
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
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
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
          final newKey =
              '$currentStart|$currentEnd|$currentBreakStart|$currentBreakEnd';
          if (currentStart == null || key != newKey) {
            if (currentDays.isNotEmpty) {
              periods.add({
                'days': List<String>.from(currentDays),
                'start': _formatTime(currentStart!),
                'end': _formatTime(currentEnd!),
                'breakStart': currentBreakStart != null
                    ? _formatTime(currentBreakStart)
                    : null,
                'breakEnd': currentBreakEnd != null
                    ? _formatTime(currentBreakEnd)
                    : null,
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
              'breakStart': currentBreakStart != null
                  ? _formatTime(currentBreakStart)
                  : null,
              'breakEnd': currentBreakEnd != null
                  ? _formatTime(currentBreakEnd)
                  : null,
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
          'breakStart': currentBreakStart != null
              ? _formatTime(currentBreakStart)
              : null,
          'breakEnd': currentBreakEnd != null
              ? _formatTime(currentBreakEnd)
              : null,
        });
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                  if (shift.code != null &&
                                      shift.code!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: accent.withAlpha(40),
                                        ),
                                      ),
                                      child: Text(
                                        shift.code!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _Badge(
                                    label: shift.isActive
                                        ? l10n.activeShiftBadge
                                        : l10n.inactiveShiftBadge,
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
                                      color: const Color(0xFF4F46E5),
                                      bg: const Color(0xFFEEF2FF),
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
                              onTap: () => context.push(
                                AppRoutes.adminShiftForm,
                                extra: shift,
                              ),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
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
                                        final abbr =
                                            dayAbbr[d] ?? d.substring(0, 2);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withAlpha(15),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            border: Border.all(
                                              color: accent.withAlpha(35),
                                            ),
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
                                        const Icon(
                                          Icons.schedule_rounded,
                                          size: 11,
                                          color: AppColors.grey500,
                                        ),
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
                                      const Icon(
                                        Icons.coffee_rounded,
                                        size: 10,
                                        color: AppColors.grey400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.breakTimeRange(
                                          p['breakStart'].toString(),
                                          p['breakEnd'].toString(),
                                        ),
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
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.assign,
                                  style: const TextStyle(
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: l10n.deleteShiftConfirmPrefix),
                      TextSpan(
                        text: '"${shift.name}"',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: "?\n\nThis action cannot be undone.",
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
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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

final shiftAssignmentsProvider =
    FutureProvider.autoDispose<List<ShiftAssignmentData>>((ref) async {
      return ref.read(adminOpsRepositoryProvider).getShiftAssignments();
    });

class _AssignShiftSheetState extends ConsumerState<_AssignShiftSheet> {
  final Set<int> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _effectiveDateCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );
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
      if (!_initializedAssignments &&
          employeesAsync.value != null &&
          widget.shift != null) {
        _initializedAssignments = true;
        final validEmpIds = employeesAsync.value!
            .where(
              (e) =>
                  e.employmentStatus != 'terminated' &&
                  (activeBranchId == null ||
                      e.branchId == null ||
                      e.branchId == activeBranchId),
            )
            .map((e) => e.id)
            .toSet();

        for (final a in assignmentsAsync.value!) {
          if (a.shiftId == widget.shift!.id &&
              (a.endDate == null || a.endDate!.isEmpty)) {
            if (validEmpIds.contains(a.employeeId)) {
              _selectedIds.add(a.employeeId);
            }
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.assignEmployeesTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        l10n.assignEmployeesSubtitle(
                          widget.shift?.name ?? 'Shift',
                          _selectedIds.length.toString(),
                        ),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.grey500,
                      size: 18,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: shifts
                      .where((s) => s.isActive)
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedShiftId = val;
                      _selectedIds.clear();
                      if (val != null && assignmentsAsync.value != null) {
                        for (final a in assignmentsAsync.value!) {
                          if (a.shiftId == val &&
                              (a.endDate == null || a.endDate!.isEmpty)) {
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                border: Border.all(color: AppColors.border(context)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.searchEmployeesHint,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.grey400,
                  ),
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
                  if (activeBranchId != null &&
                      e.branchId != null &&
                      e.branchId != activeBranchId) {
                    return false;
                  }
                  return true;
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (e) =>
                            e.name.toLowerCase().contains(_searchQuery) ||
                            (e.employeeId ?? '').toLowerCase().contains(
                              _searchQuery,
                            ),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No employees found',
                      style: TextStyle(fontSize: 13, color: AppColors.grey400),
                    ),
                  );
                }

                final allFilteredSelected = filtered.every(
                  (e) => _selectedIds.contains(e.id),
                );

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
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                                allFilteredSelected
                                    ? l10n.deselectAll
                                    : l10n.selectAll,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: allFilteredSelected
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                l10n.employeesCountLabel(
                                  filtered.length.toString(),
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey400,
                                ),
                              ),
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
                          final isThisShift =
                              widget.shift != null &&
                              activeAssign?.shiftId == widget.shift!.id;
                          final isOtherShift =
                              activeAssign != null && !isThisShift;

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
                                horizontal: 12,
                                vertical: 10,
                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success
                                                      .withAlpha(25),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.success
                                                        .withAlpha(60),
                                                  ),
                                                ),
                                                child: Text(
                                                  l10n.assignedBadge,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ] else if (isOtherShift) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.info
                                                      .withAlpha(25),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.info
                                                        .withAlpha(60),
                                                  ),
                                                ),
                                                child: Text(
                                                  activeAssign.shiftName ??
                                                      l10n.otherShiftBadge,
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
                                          Text(
                                            emp.employeeId!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey400,
                                            ),
                                          ),
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
                child: Text(
                  'Error loading employees',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              border: const Border(top: BorderSide(color: AppColors.grey100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedIds.isEmpty || _isLoading
                        ? null
                        : _assign,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withAlpha(160),
                      disabledBackgroundColor: AppColors.primary.withAlpha(120),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedIds.isEmpty
                                ? l10n.assign
                                : l10n.assignCount(
                                    _selectedIds.length.toString(),
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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
        const SnackBar(
          content: Text('Please select a shift schedule'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      final effDate = _effectiveDateCtrl.text.trim();
      final endDate = _endDateCtrl.text.trim();

      await repo.assignShift(
        targetShiftId,
        null,
        employeeIds: _selectedIds.toList(),
        effectiveDate: effDate.isNotEmpty ? effDate : null,
        endDate: endDate.isNotEmpty ? endDate : null,
      );

      ref.invalidate(shiftsProvider);
      ref.invalidate(shiftAssignmentsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.assignSuccess(_selectedIds.length.toString()),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.assignFailedError(e.toString())),
            backgroundColor: AppColors.danger,
          ),
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
              child: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noShiftsYet,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createFirstShiftDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppLocalizations.of(context)!.createFirstShiftBtn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.danger,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.failedToLoadShifts,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.checkConnectionRetry,
            style: const TextStyle(color: AppColors.grey500, fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              AppLocalizations.of(context)!.tryAgain,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftAssignmentsTab extends ConsumerStatefulWidget {
  const _ShiftAssignmentsTab();

  @override
  ConsumerState<_ShiftAssignmentsTab> createState() =>
      _ShiftAssignmentsTabState();
}

class _ShiftAssignmentsTabState extends ConsumerState<_ShiftAssignmentsTab> {
  String _searchQuery = '';
  int? _selectedShiftFilter; // null = all

  Widget _buildScheduleBadges(
    Map<String, dynamic>? schedule,
    BuildContext context,
  ) {
    if (schedule == null || schedule.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      if (sched is Map &&
          (sched['is_working'] == true || sched['is_working'] == 1)) {
        final start = _fmtTime(sched['start']?.toString());
        final end = _fmtTime(sched['end']?.toString());
        badges.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Text(
              '${d['short']}: $start - $end',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
          ),
        );
      }
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 4, children: badges);
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

  Widget _buildAvatar(ShiftAssignmentData item, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = item.employeeName ?? 'E';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';

    if (item.employeePhoto != null && item.employeePhoto!.isNotEmpty) {
      final imgUrl = item.employeePhoto!.startsWith('http')
          ? item.employeePhoto!
          : '${DioClient.storageUrl}/${item.employeePhoto!.startsWith('/') ? item.employeePhoto!.substring(1) : item.employeePhoto!}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 40,
            height: 40,
            color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFE0E7FF),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackAvatar(initial, isDark),
        ),
      );
    }
    return _buildFallbackAvatar(initial, isDark);
  }

  Widget _buildFallbackAvatar(String initial, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFE0E7FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  void _showEditModal(ShiftAssignmentData assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditShiftAssignmentModal(
        assignment: assignment,
        onSaved: () {
          ref.invalidate(shiftAssignmentsProvider);
          ref.invalidate(shiftsProvider);
        },
      ),
    );
  }

  Future<void> _confirmDelete(ShiftAssignmentData item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Shift Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove the shift assignment for ${item.employeeName ?? "this employee"}?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminOpsRepositoryProvider).deleteShiftAssignment(item.id);
        ref.invalidate(shiftAssignmentsProvider);
        ref.invalidate(shiftsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shift assignment deleted.'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider);
    final shiftsAsync = ref.watch(shiftsProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);
    final activeBranchId = ref.watch(branchSwitchProvider).activeBranchId;

    return assignmentsAsync.when(
      data: (rawAssignments) {
        final shiftsList = shiftsAsync.value ?? [];
        final employeesList = employeesAsync.value ?? [];

        // Deduplicate by employeeId to strictly show 1 active shift card per employee
        final Map<int, ShiftAssignmentData> uniqueMap = {};
        for (final a in rawAssignments) {
          if (!uniqueMap.containsKey(a.employeeId)) {
            uniqueMap[a.employeeId] = a;
          }
        }
        final assignments = uniqueMap.values.toList();

        // KPI Computations
        final activeAssignedEmpIds = assignments
            .where((a) => a.endDate == null || a.endDate!.isEmpty)
            .map((a) => a.employeeId)
            .toSet();

        final validEmployees = employeesList.where((e) {
          final isNotTerminated = e.employmentStatus != 'terminated';
          final matchesBranch = activeBranchId == null ||
              e.branchId == null ||
              e.branchId == activeBranchId;
          return isNotTerminated && matchesBranch;
        }).toList();

        final assignedCount = activeAssignedEmpIds.length;
        final unassignedCount = (validEmployees.length - assignedCount).clamp(0, 9999);
        final shiftsInUseCount = assignments.map((a) => a.shiftId).toSet().length;
        final availableShiftsCount = shiftsList.length;

        // Filtering
        final filtered = assignments.where((a) {
          final matchesShift = _selectedShiftFilter == null ||
              a.shiftId == _selectedShiftFilter;
          final name = (a.employeeName ?? '').toLowerCase();
          final code = (a.employeeCode ?? '').toLowerCase();
          final shift = (a.shiftName ?? '').toLowerCase();
          final pos = (a.employeePosition ?? '').toLowerCase();
          final q = _searchQuery.toLowerCase();
          final matchesSearch = q.isEmpty ||
              name.contains(q) ||
              code.contains(q) ||
              shift.contains(q) ||
              pos.contains(q);
          return matchesShift && matchesSearch;
        }).toList();

        return CustomScrollView(
          slivers: [
            // ── 1. KPI Metric Summary Cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildKpiCard(
                          title: 'Assigned Staff',
                          value: '$assignedCount',
                          subtitle: 'With active shift',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF4F46E5),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Unassigned Staff',
                          value: '$unassignedCount',
                          subtitle: 'Needing assignment',
                          icon: Icons.person_off_rounded,
                          color: unassignedCount > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Shifts in Use',
                          value: '$shiftsInUseCount',
                          subtitle: 'Active schedules',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          title: 'Available Shifts',
                          value: '$availableShiftsCount',
                          subtitle: 'Total schedules',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFF8B5CF6),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── 2. Search & Shift Filter Row ──
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search employee, ID, shift, position…',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDarkElevated
                            : AppColors.surface(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                  ),

                  // Shift Filter Chips
                  if (shiftsList.isNotEmpty)
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ChoiceChip(
                            label: Text('All Shifts (${assignments.length})'),
                            selected: _selectedShiftFilter == null,
                            onSelected: (_) =>
                                setState(() => _selectedShiftFilter = null),
                            selectedColor: const Color(0xFF8B5CF6),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedShiftFilter == null
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.grey300
                                      : AppColors.grey700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...shiftsList.map((s) {
                            final count = assignments
                                .where((a) => a.shiftId == s.id)
                                .length;
                            final isSelected = _selectedShiftFilter == s.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${s.name} ($count)'),
                                selected: isSelected,
                                onSelected: (_) => setState(
                                  () => _selectedShiftFilter =
                                      isSelected ? null : s.id,
                                ),
                                selectedColor: const Color(0xFF8B5CF6),
                                labelStyle: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.grey300
                                          : AppColors.grey700),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── 3. Assignment Cards List ──
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: isDark ? AppColors.grey600 : AppColors.grey300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No shift assignments found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try modifying your search or filter keywords.',
                          style: TextStyle(fontSize: 12, color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border(context)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 0 : 6),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildAvatar(item, context),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.employeeName ?? 'Employee #${item.employeeId}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (item.employeeCode != null &&
                                                item.employeeCode!.isNotEmpty)
                                              Text(
                                                item.employeeCode!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.grey500,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            if (item.employeePosition != null &&
                                                item.employeePosition!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              const Text('•', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  item.employeePosition!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Actions: Edit and Delete
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFF6366F1),
                                      size: 19,
                                    ),
                                    tooltip: 'Edit Assignment',
                                    onPressed: () => _showEditModal(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.danger,
                                      size: 19,
                                    ),
                                    tooltip: 'Delete Assignment',
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDarkElevated
                                      : AppColors.grey50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 14,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              item.shiftName ?? 'Shift #${item.shiftId}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                                color: AppColors.textPrimary(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withAlpha(20),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${item.effectiveDate ?? '—'} ${item.endDate != null && item.endDate!.isNotEmpty ? '→ ${item.endDate}' : '(Indefinite)'}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.shiftSchedule != null) ...[
                                      const SizedBox(height: 8),
                                      _buildScheduleBadges(item.shiftSchedule, context),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () =>
          const LoadingIndicator(message: 'Loading shift assignments…'),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(shiftAssignmentsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey500,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Shift Assignment Modal ─────────────────────────────────────────────
class _EditShiftAssignmentModal extends ConsumerStatefulWidget {
  final ShiftAssignmentData assignment;
  final VoidCallback onSaved;
  const _EditShiftAssignmentModal({
    required this.assignment,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditShiftAssignmentModal> createState() =>
      _EditShiftAssignmentModalState();
}

class _EditShiftAssignmentModalState
    extends ConsumerState<_EditShiftAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _effectiveDateCtrl;
  late TextEditingController _endDateCtrl;
  int? _selectedShiftId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedShiftId = widget.assignment.shiftId;
    _effectiveDateCtrl = TextEditingController(
      text: widget.assignment.effectiveDate ??
          DateTime.now().toIso8601String().split('T')[0],
    );
    _endDateCtrl = TextEditingController(text: widget.assignment.endDate ?? '');
  }

  @override
  void dispose() {
    _effectiveDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedShiftId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(adminOpsRepositoryProvider).updateShiftAssignment(
        widget.assignment.id,
        {
          'shift_id': _selectedShiftId,
          'effective_date': _effectiveDateCtrl.text.trim(),
          if (_endDateCtrl.text.trim().isNotEmpty)
            'end_date': _endDateCtrl.text.trim()
          else
            'end_date': null,
        },
      );
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift assignment updated.'),
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
    final shiftsAsync = ref.watch(shiftsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom +
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Shift Assignment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        widget.assignment.employeeName ?? 'Employee #${widget.assignment.employeeId}',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shift selector
              shiftsAsync.when(
                data: (shifts) => DropdownButtonFormField<int>(
                  initialValue: _selectedShiftId,
                  decoration: InputDecoration(
                    labelText: 'Shift Schedule *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                  ),
                  items: shifts
                      .where((s) => s.isActive)
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedShiftId = val),
                  validator: (val) => val == null ? 'Please select a shift' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text('Failed to load shifts', style: TextStyle(color: AppColors.danger)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _effectiveDateCtrl,
                decoration: InputDecoration(
                  labelText: 'Effective Date * (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter effective date' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _endDateCtrl,
                decoration: InputDecoration(
                  labelText: 'End Date (Optional) (YYYY-MM-DD)',
                  prefixIcon: const Icon(Icons.event_busy_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Update Assignment',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
