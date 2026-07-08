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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = _cardGradients[colorIndex];
    final accent = _cardAccents[colorIndex];
    final workDays = shift.workDays ?? [];

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
                // Icon circle
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
                      Text(
                        shift.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              '${shift.startTime} – ${shift.endTime}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1, color: accent.withAlpha(30)),
          ),

          // ── Stats row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.people_alt_rounded,
                  label: '${shift.employeesCount ?? 0} Assigned',
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: workDays.isEmpty
                      ? _StatChip(icon: Icons.event_busy_rounded, label: 'No days set', color: AppColors.grey400)
                      : _DayChips(days: workDays, accent: accent),
                ),
              ],
            ),
          ),

          // ── Assign button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAssignDialog(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Assign Employee'),
              ),
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
  int? _selectedEmployeeId;
  bool _isLoading = false;

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
                        'Assign Employee',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey800),
                      ),
                      Text(
                        widget.shift.name,
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
            const SizedBox(height: 20),

            // Dropdown
            const Text(
              'Select Employee',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey700),
            ),
            const SizedBox(height: 8),
            employeesAsync.when(
              data: (employees) => DropdownButtonFormField<int>(
                initialValue: _selectedEmployeeId,
                decoration: InputDecoration(
                  hintText: 'Choose an employee...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                ),
                items: employees
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
              loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const Text('Error loading employees', style: TextStyle(color: AppColors.danger)),
            ),

            const SizedBox(height: 24),

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
                    onPressed: _selectedEmployeeId == null || _isLoading ? null : _assign,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Assign', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
      await ref.read(adminOpsRepositoryProvider).assignShift(widget.shift.id, _selectedEmployeeId!);
      ref.invalidate(shiftsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Shift assigned successfully'), backgroundColor: AppColors.success),
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
