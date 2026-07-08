import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

// ─── Color palette per card index ───────────────────────────────────────────
const _cardGradients = [
  [Color(0xFFFFF7ED), Color(0xFFFFEDD5)], // orange tint
  [Color(0xFFEFF6FF), Color(0xFFDBEAFE)], // blue tint
  [Color(0xFFF0FDF4), Color(0xFFDCFCE7)], // green tint
  [Color(0xFFFDF4FF), Color(0xFFF3E8FF)], // purple tint
  [Color(0xFFFFFBEB), Color(0xFFFEF3C7)], // amber tint
];

const _cardAccents = [
  AppColors.primary,
  AppColors.secondary,
  Color(0xFF22C55E),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
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
            padding: const EdgeInsets.only(right: 8),
            child: shiftsAsync.maybeWhen(
              data: (shifts) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${shifts.length} shifts',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
                  child: _ShiftCard(shift: shifts[i], colorIndex: i % _cardGradients.length),
                ),
              ),
        loading: () => const LoadingIndicator(message: 'Loading shifts...'),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(shiftsProvider)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminShiftForm),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Shift',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
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
    'monday': 'Mon', 'tuesday': 'Tue', 'wednesday': 'Wed',
    'thursday': 'Thu', 'friday': 'Fri', 'saturday': 'Sat', 'sunday': 'Sun',
  };
  static const _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  String _formatTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${parts[1]} $ampm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = _cardGradients[colorIndex];
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: accent.withAlpha(40)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.wb_sunny_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shift.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey800),
                            ),
                          ),
                          if (shift.code != null && shift.code!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shift.code!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Status badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: shift.isActive ? const Color(0xFFDCFCE7) : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              shift.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: shift.isActive ? const Color(0xFF16A34A) : AppColors.grey500,
                              ),
                            ),
                          ),
                          if (shift.isOvernight) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'OVERNIGHT',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  children: [
                    _IconBtn(
                      icon: Icons.edit_rounded,
                      color: AppColors.secondary,
                      bg: AppColors.secondaryLight,
                      onTap: () => context.push(AppRoutes.adminShiftForm, extra: shift),
                    ),
                    const SizedBox(width: 4),
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

          // ── Divider ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: accent.withAlpha(30)),
          ),

          // ── Schedule grid ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: periods.map((p) {
                final days = (p['days'] as List<String>);
                final dayLabels = days.map((d) => _dayAbbr[d] ?? d.substring(0, 2)).join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        // Day labels
                        Expanded(
                          flex: 3,
                          child: Text(
                            dayLabels,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        // Time range
                        Text(
                          '${p['start']} – ${p['end']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
                        ),
                        if (p['breakStart'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(150),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Brk ${p['breakStart']}–${p['breakEnd']}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.grey500),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Rules row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatChip(icon: Icons.timer_outlined, label: '${shift.gracePeriod}m grace', color: accent),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.more_time_rounded, label: 'OT≥${shift.overtimeThreshold}m', color: accent),
              ],
            ),
          ),

          // ── Assigned count + Assign button ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.people_alt_rounded,
                  label: '${shift.employeesCount ?? 0} assigned',
                  color: accent,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAssignDialog(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                  label: const Text('Assign'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Delete Shift', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${shift.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.grey600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(adminOpsRepositoryProvider).deleteShift(shift.id);
        ref.invalidate(shiftsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ ${shift.name} deleted'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Failed to delete: $e'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AssignShiftDialog(shift: shift),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ignore: unused_element
class _DayChips extends StatelessWidget {
  final List<dynamic> days;
  final Color accent;
  const _DayChips({required this.days, required this.accent});

  static const _abbr = {
    'monday': 'Mo', 'tuesday': 'Tu', 'wednesday': 'We',
    'thursday': 'Th', 'friday': 'Fr', 'saturday': 'Sa', 'sunday': 'Su',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((d) {
        final label = _abbr[d.toString().toLowerCase()] ?? d.toString().substring(0, 2);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
        );
      }).toList(),
    );
  }
}

// ─── Assign Dialog ────────────────────────────────────────────────────────────
class _AssignShiftDialog extends ConsumerStatefulWidget {
  final ShiftData shift;
  const _AssignShiftDialog({required this.shift});

  @override
  ConsumerState<_AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends ConsumerState<_AssignShiftDialog> {
  final Set<int> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Employees',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey800),
                      ),
                      Text(
                        '${widget.shift.name} · ${_selectedIds.length} selected',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, color: AppColors.grey500, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search + Select All
            Row(
              children: [
                Expanded(
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
                        hintText: 'Search employees...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.grey400),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Employee list
            Flexible(
              child: employeesAsync.when(
                data: (allEmployees) {
                  final filtered = _searchQuery.isEmpty
                      ? allEmployees
                      : allEmployees.where((e) =>
                          e.name.toLowerCase().contains(_searchQuery) ||
                          (e.employeeId ?? '').toLowerCase().contains(_searchQuery)
                        ).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No employees found', style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                    );
                  }

                  final allFilteredSelected = filtered.every((e) => _selectedIds.contains(e.id));

                  return SizedBox(
                    height: 240,
                    child: Column(
                      children: [
                        // Select All toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (allFilteredSelected) {
                                for (final e in filtered) { _selectedIds.remove(e.id); }
                              } else {
                                for (final e in filtered) { _selectedIds.add(e.id); }
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  allFilteredSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  size: 18,
                                  color: allFilteredSelected ? AppColors.primary : AppColors.grey400,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  allFilteredSelected ? 'Deselect All' : 'Select All',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: allFilteredSelected ? AppColors.primary : AppColors.grey600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // List
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final emp = filtered[i];
                              final isSelected = _selectedIds.contains(emp.id);
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryLight : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? AppColors.primary.withAlpha(50) : AppColors.grey100),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                        size: 18,
                                        color: isSelected ? AppColors.primary : AppColors.grey300,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(emp.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.grey800)),
                                            if (emp.employeeId != null)
                                              Text(emp.employeeId!, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => const SizedBox(height: 240, child: Center(child: Text('Error loading employees', style: TextStyle(color: AppColors.danger)))),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedIds.isEmpty || _isLoading ? null : _assign,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Assign ${_selectedIds.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            content: Text('✅ $successCount assigned${failCount > 0 ? ', $failCount failed' : ''}'),
            backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Shifts Yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.grey800),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Shift', style: TextStyle(fontWeight: FontWeight.w600)),
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
            decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load shifts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.grey700)),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
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
