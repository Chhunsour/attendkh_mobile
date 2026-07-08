import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';

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
  late TextEditingController _codeCtrl;
  late TextEditingController _graceCtrl;
  late TextEditingController _overtimeCtrl;

  bool _isOvernight = false;
  bool _isActive = true;

  // Per-day schedule
  static const _dayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _graceCtrl = TextEditingController(text: s?.gracePeriod.toString() ?? '15');
    _overtimeCtrl = TextEditingController(text: s?.overtimeThreshold.toString() ?? '30');
    _isOvernight = s?.isOvernight ?? false;
    _isActive = s?.isActive ?? true;

    // Init schedule from existing shift or defaults
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

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _graceCtrl.dispose();
    _overtimeCtrl.dispose();
    super.dispose();
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  void _copyMondayToAll() {
    final monday = _startTimes['monday']!;
    setState(() {
      for (final day in _dayOrder) {
        if (_isWorking[day]! && day != 'monday') {
          _startTimes[day] = monday;
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
        const SnackBar(content: Text('Select at least one working day'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
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
      final body = {
        'name': _nameCtrl.text,
        'code': _codeCtrl.text.isEmpty ? null : _codeCtrl.text,
        'schedule': schedule,
        'grace_period': int.tryParse(_graceCtrl.text) ?? 15,
        'overtime_threshold': int.tryParse(_overtimeCtrl.text) ?? 30,
        'is_overnight': _isOvernight,
        'is_active': _isActive,
      };

      if (widget.shift == null) {
        await repo.createShift(
          name: body['name'] as String,
          startTime: body['schedule'] != null ? _fmt(_startTimes['monday']!) : '09:00',
          endTime: body['schedule'] != null ? _fmt(_endTimes['monday']!) : '17:00',
          code: body['code'] as String?,
          gracePeriod: body['grace_period'] as int?,
          overtimeThreshold: body['overtime_threshold'] as int?,
          isOvernight: body['is_overnight'] as bool?,
          isActive: body['is_active'] as bool?,
        );
      } else {
        await repo.updateShift(
          widget.shift!.id,
          name: body['name'] as String,
          startTime: _fmt(_startTimes['monday']!),
          endTime: _fmt(_endTimes['monday']!),
          code: body['code'] as String?,
          gracePeriod: body['grace_period'] as int?,
          overtimeThreshold: body['overtime_threshold'] as int?,
          isOvernight: body['is_overnight'] as bool?,
          isActive: body['is_active'] as bool?,
        );
      }
      ref.invalidate(shiftsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Shift saved'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shift != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Schedule' : 'Add Schedule',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.grey800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: General ───────────────────────────────────
              _sectionHeader('General Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDec('Schedule Name', 'e.g. Standard Office Hours'),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: _inputDec('Code', 'e.g. STD-01'),
              ),
              const SizedBox(height: 24),

              // ── Section: Weekly Schedule ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader('Weekly Schedule'),
                  TextButton.icon(
                    onPressed: _copyMondayToAll,
                    icon: const Icon(Icons.content_copy, size: 14, color: AppColors.primary),
                    label: const Text('Copy Mon to All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AppColors.primaryLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 52, child: Text('Day', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.5))),
                          Expanded(child: Text('Work?', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.5))),
                          Expanded(flex: 2, child: Text('Start', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.5))),
                          Expanded(flex: 2, child: Text('End', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.5))),
                          Expanded(flex: 2, child: Text('Break', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.5))),
                        ],
                      ),
                    ),
                    // Day rows
                    ..._dayOrder.asMap().entries.map((entry) {
                      final i = entry.key;
                      final day = entry.value;
                      final working = _isWorking[day]!;
                      return Container(
                        decoration: BoxDecoration(
                          border: i < 6 ? const Border(bottom: BorderSide(color: AppColors.grey100)) : null,
                          color: working ? Colors.white : const Color(0xFFF9FAFB),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    _dayLabels[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: working ? AppColors.grey800 : AppColors.grey400,
                                    ),
                                  ),
                                ),
                              ),
                              // Work toggle
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: working,
                                      onChanged: (v) => setState(() => _isWorking[day] = v ?? false),
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      side: BorderSide(color: working ? AppColors.primary : AppColors.grey300, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              // Start time
                              Expanded(
                                flex: 2,
                                child: _timeBtn(
                                  _startTimes[day]!,
                                  working,
                                  () async {
                                    final t = await _pickTime(_startTimes[day]!);
                                    if (t != null) setState(() => _startTimes[day] = t);
                                  },
                                ),
                              ),
                              // End time
                              Expanded(
                                flex: 2,
                                child: _timeBtn(
                                  _endTimes[day]!,
                                  working,
                                  () async {
                                    final t = await _pickTime(_endTimes[day]!);
                                    if (t != null) setState(() => _endTimes[day] = t);
                                  },
                                ),
                              ),
                              // Break
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: working
                                            ? () async {
                                                final t = await _pickTime(_breakStarts[day] ?? const TimeOfDay(hour: 12, minute: 0));
                                                if (t != null) setState(() => _breakStarts[day] = t);
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                                          child: Text(
                                            _breakStarts[day] != null ? _fmt(_breakStarts[day]!) : '—',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: working && _breakStarts[day] != null ? AppColors.grey600 : AppColors.grey300,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1),
                                      child: Text('–', style: TextStyle(fontSize: 10, color: AppColors.grey300)),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: working
                                            ? () async {
                                                final t = await _pickTime(_breakEnds[day] ?? const TimeOfDay(hour: 13, minute: 0));
                                                if (t != null) setState(() => _breakEnds[day] = t);
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                                          child: Text(
                                            _breakEnds[day] != null ? _fmt(_breakEnds[day]!) : '—',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: working && _breakEnds[day] != null ? AppColors.grey600 : AppColors.grey300,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Rules ─────────────────────────────────────
              _sectionHeader('Rules & Allowances'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _graceCtrl,
                      decoration: _inputDec('Grace Period (min)', '15'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _overtimeCtrl,
                      decoration: _inputDec('OT Threshold (min)', '30'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Toggles ────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Overnight Shift', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Shift crosses midnight', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                      value: _isOvernight,
                      onChanged: (v) => setState(() => _isOvernight = v),
                      activeThumbColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Active Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Available for assignment', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeThumbColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey800)),
    );
  }

  InputDecoration _inputDec(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.grey200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _timeBtn(TimeOfDay time, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Text(
          _fmt(time),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.grey800 : AppColors.grey300,
          ),
        ),
      ),
    );
  }
}