import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class AdminShiftFormScreen extends ConsumerStatefulWidget {
  final ShiftData? shift;
  const AdminShiftFormScreen({super.key, this.shift});

  @override
  ConsumerState<AdminShiftFormScreen> createState() => _AdminShiftFormScreenState();
}

class _AdminShiftFormScreenState extends ConsumerState<AdminShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;

  bool _isOvernight = false;
  bool _isActive = true;

  static const _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final Map<String, bool> _isWorking = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};
  final Map<String, TimeOfDay?> _breakStarts = {};
  final Map<String, TimeOfDay?> _breakEnds = {};

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _isOvernight = s?.isOvernight ?? false;
    _isActive = s?.isActive ?? true;

    for (var i = 0; i < _dayOrder.length; i++) {
      final day = _dayOrder[i];
      final ds = s?.schedule?[day];
      if (ds != null) {
        _isWorking[day] = ds.isWorking;
        _startTimes[day] = _parseTime(ds.start);
        _endTimes[day] = _parseTime(ds.end);
        _breakStarts[day] = ds.breakStart != null ? _parseTime(ds.breakStart!) : null;
        _breakEnds[day] = ds.breakEnd != null ? _parseTime(ds.breakEnd!) : null;
      } else {
        final isWeekend = day == 'saturday' || day == 'sunday';
        _isWorking[day] = !isWeekend;
        _startTimes[day] = const TimeOfDay(hour: 9, minute: 0);
        _endTimes[day] = const TimeOfDay(hour: 17, minute: 0);
        _breakStarts[day] = isWeekend ? null : const TimeOfDay(hour: 12, minute: 0);
        _breakEnds[day] = isWeekend ? null : const TimeOfDay(hour: 13, minute: 0);
      }
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // 24-hour format for API
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // 12-hour format for display
  String _fmtDisplay(TimeOfDay t) {
    final h = t.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  void _copyMondayToAll() {
    setState(() {
      for (final day in _dayOrder) {
        if (_isWorking[day]! && day != 'monday') {
          _startTimes[day] = _startTimes['monday']!;
          _endTimes[day] = _endTimes['monday']!;
          _breakStarts[day] = _breakStarts['monday'];
          _breakEnds[day] = _breakEnds['monday'];
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hasWorkingDay = _isWorking.values.any((w) => w);
    if (!hasWorkingDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectOneWorkingDayError),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Build full per-day schedule map
      final schedule = <String, Map<String, dynamic>>{};
      for (final day in _dayOrder) {
        schedule[day] = {
          'is_working': _isWorking[day],
          'start': _fmt(_startTimes[day]!),
          'end': _fmt(_endTimes[day]!),
          'break_start': _breakStarts[day] != null ? _fmt(_breakStarts[day]!) : null,
          'break_end': _breakEnds[day] != null ? _fmt(_breakEnds[day]!) : null,
        };
      }

      final repo = ref.read(adminOpsRepositoryProvider);

      if (widget.shift == null) {
        await repo.createShift(
          name: _nameCtrl.text.trim(),
          startTime: _fmt(_startTimes['monday']!),
          endTime: _fmt(_endTimes['monday']!),
          code: null,
          gracePeriod: 15,
          overtimeThreshold: 30,
          isOvernight: _isOvernight,
          isActive: _isActive,
          schedule: schedule,
        );
      } else {
        await repo.updateShift(
          widget.shift!.id,
          name: _nameCtrl.text.trim(),
          startTime: _fmt(_startTimes['monday']!),
          endTime: _fmt(_endTimes['monday']!),
          code: null,
          gracePeriod: 15,
          overtimeThreshold: 30,
          isOvernight: _isOvernight,
          isActive: _isActive,
          schedule: schedule,
        );
      }

      ref.invalidate(shiftsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(widget.shift == null
                    ? AppLocalizations.of(context)!.shiftCreatedSuccess
                    : AppLocalizations.of(context)!.shiftUpdatedSuccess),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shiftFailedError(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.shift != null;
    final dayLabels = [l10n.dayMo, l10n.dayTu, l10n.dayWe, l10n.dayTh, l10n.dayFr, l10n.daySa, l10n.daySu];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey100),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.grey700),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? l10n.editScheduleTitle : l10n.newScheduleTitle,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
            ),
            Text(
              isEdit ? l10n.editScheduleSubtitle : l10n.newScheduleSubtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Scrollable body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Section 1: General
                    _SectionCard(
                      icon: Icons.badge_rounded,
                      title: l10n.generalInfoTitle,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _inputDec(
                              l10n.scheduleNameLabel,
                              l10n.scheduleNameHint,
                              Icons.drive_file_rename_outline_rounded,
                            ),
                            validator: (v) => v!.trim().isEmpty ? l10n.nameRequiredError : null,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _isActive
                                        ? AppColors.success.withAlpha(20)
                                        : AppColors.grey100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isActive
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 18,
                                    color: _isActive ? AppColors.success : AppColors.grey400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.activeStatusTitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey700,
                                        ),
                                      ),
                                      const Text(
                                        'Ready for employee shift assignments',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: _isActive,
                                    onChanged: (v) => setState(() => _isActive = v),
                                    activeThumbColor: AppColors.success,
                                    trackOutlineColor:
                                        WidgetStateProperty.all(Colors.transparent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Weekly Schedule
                    _SectionCard(
                      icon: Icons.calendar_month_rounded,
                      title: l10n.weeklyScheduleTitle,
                      childPadding: EdgeInsets.zero,
                      trailing: TextButton.icon(
                        onPressed: _copyMondayToAll,
                        icon: const Icon(Icons.content_copy_rounded, size: 13),
                        label: Text(l10n.copyMonToAll),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      child: Column(
                        children: _dayOrder.asMap().entries.map((entry) {
                          final i = entry.key;
                          final day = entry.value;
                          final working = _isWorking[day]!;
                          final isWeekend = day == 'saturday' || day == 'sunday';
                          final isLast = i == _dayOrder.length - 1;

                          return Column(
                            children: [
                              _DayRow(
                                label: dayLabels[i],
                                isWorking: working,
                                isWeekend: isWeekend,
                                startTime: _startTimes[day]!,
                                endTime: _endTimes[day]!,
                                breakStart: _breakStarts[day],
                                breakEnd: _breakEnds[day],
                                fmtDisplay: _fmtDisplay,
                                onToggle: (v) => setState(() => _isWorking[day] = v),
                                onTapStart: () async {
                                  final t = await _pickTime(_startTimes[day]!);
                                  if (t != null) setState(() => _startTimes[day] = t);
                                },
                                onTapEnd: () async {
                                  final t = await _pickTime(_endTimes[day]!);
                                  if (t != null) setState(() => _endTimes[day] = t);
                                },
                                onTapBreakStart: () async {
                                  final t = await _pickTime(
                                    _breakStarts[day] ?? const TimeOfDay(hour: 12, minute: 0),
                                  );
                                  if (t != null) setState(() => _breakStarts[day] = t);
                                },
                                onTapBreakEnd: () async {
                                  final t = await _pickTime(
                                    _breakEnds[day] ?? const TimeOfDay(hour: 13, minute: 0),
                                  );
                                  if (t != null) setState(() => _breakEnds[day] = t);
                                },
                                onClearBreak: () => setState(() {
                                  _breakStarts[day] = null;
                                  _breakEnds[day] = null;
                                }),
                              ),
                              if (!isLast)
                                const Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                    color: AppColors.grey100),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom save button ────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border: const Border(top: BorderSide(color: AppColors.grey100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          isEdit ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                          size: 20),
                  label: Text(
                    _isLoading
                        ? l10n.saving
                        : (isEdit ? l10n.saveChangesBtn : l10n.createScheduleBtn),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
      labelStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey600),
      filled: true,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }
}

// ─── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry childPadding;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.childPadding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey700),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(padding: childPadding, child: child),
        ),
      ],
    );
  }
}

// ─── Day Row ──────────────────────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final String label;
  final bool isWorking;
  final bool isWeekend;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String Function(TimeOfDay) fmtDisplay;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;
  final VoidCallback onTapBreakStart;
  final VoidCallback onTapBreakEnd;
  final VoidCallback onClearBreak;

  const _DayRow({
    required this.label,
    required this.isWorking,
    required this.isWeekend,
    required this.startTime,
    required this.endTime,
    required this.breakStart,
    required this.breakEnd,
    required this.fmtDisplay,
    required this.onToggle,
    required this.onTapStart,
    required this.onTapEnd,
    required this.onTapBreakStart,
    required this.onTapBreakEnd,
    required this.onClearBreak,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isWeekend ? const Color(0xFF8B5CF6) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day label pill
          Container(
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isWorking ? accent.withAlpha(15) : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isWorking ? accent : AppColors.grey400,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Time content
          Expanded(
            child: isWorking
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Work hours
                      Row(
                        children: [
                          _TimeChip(
                              time: fmtDisplay(startTime), onTap: onTapStart, color: accent),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 11, color: AppColors.grey400),
                          ),
                          _TimeChip(
                              time: fmtDisplay(endTime), onTap: onTapEnd, color: accent),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Break row
                      Row(
                        children: [
                          const Icon(Icons.coffee_rounded, size: 11, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          _TimeChip(
                            time: breakStart != null ? fmtDisplay(breakStart!) : AppLocalizations.of(context)!.startTimeLabel,
                            onTap: onTapBreakStart,
                            color: AppColors.grey500,
                            small: true,
                            placeholder: breakStart == null,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child:
                                Text('–', style: TextStyle(fontSize: 10, color: AppColors.grey400)),
                          ),
                          _TimeChip(
                            time: breakEnd != null ? fmtDisplay(breakEnd!) : AppLocalizations.of(context)!.endTimeLabel,
                            onTap: onTapBreakEnd,
                            color: AppColors.grey500,
                            small: true,
                            placeholder: breakEnd == null,
                          ),
                          if (breakStart != null || breakEnd != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onClearBreak,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.grey200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child:
                                    const Icon(Icons.close_rounded, size: 10, color: AppColors.grey500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  )
                : Text(
                    isWeekend ? AppLocalizations.of(context)!.scheduledDayOff : AppLocalizations.of(context)!.dayOff,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey400, fontStyle: FontStyle.italic),
                  ),
          ),

          // Toggle
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isWorking,
              onChanged: onToggle,
              activeThumbColor: accent,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Time Chip ────────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  final Color color;
  final bool small;
  final bool placeholder;

  const _TimeChip({
    required this.time,
    required this.onTap,
    required this.color,
    this.small = false,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 6 : 9, vertical: small ? 3 : 5),
        decoration: BoxDecoration(
          color: placeholder ? AppColors.grey100 : color.withAlpha(small ? 12 : 15),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: placeholder ? AppColors.grey200 : color.withAlpha(small ? 35 : 45),
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: small ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: placeholder ? AppColors.grey400 : color,
          ),
        ),
      ),
    );
  }
}