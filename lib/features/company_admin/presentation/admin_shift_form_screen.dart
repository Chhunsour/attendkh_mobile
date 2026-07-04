import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';

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
  late TextEditingController _breakCtrl;
  late TextEditingController _graceCtrl;
  late TextEditingController _overtimeCtrl;
  
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  
  List<String> _workDays = ['mon', 'tue', 'wed', 'thu', 'fri'];
  bool _isOvernight = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _breakCtrl = TextEditingController(text: s?.breakDuration?.toString() ?? '60');
    _graceCtrl = TextEditingController(text: s?.gracePeriod?.toString() ?? '15');
    _overtimeCtrl = TextEditingController(text: s?.overtimeThreshold?.toString() ?? '30');

    if (s != null) {
      if (s.startTime.isNotEmpty) _startTime = _parseTime(s.startTime);
      if (s.endTime.isNotEmpty) _endTime = _parseTime(s.endTime);
      _workDays = s.workDays ?? _workDays;
      _isOvernight = s.isOvernight ?? false;
      _isActive = s.isActive ?? true;
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _breakCtrl.dispose();
    _graceCtrl.dispose();
    _overtimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one work day'), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      if (widget.shift == null) {
        await repo.createShift(
          name: _nameCtrl.text,
          code: _codeCtrl.text.isEmpty ? null : _codeCtrl.text,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          breakDuration: int.tryParse(_breakCtrl.text),
          gracePeriod: int.tryParse(_graceCtrl.text),
          overtimeThreshold: int.tryParse(_overtimeCtrl.text),
          workDays: _workDays,
          isOvernight: _isOvernight,
          isActive: _isActive,
        );
      } else {
        await repo.updateShift(
          widget.shift!.id,
          name: _nameCtrl.text,
          code: _codeCtrl.text.isEmpty ? null : _codeCtrl.text,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          breakDuration: int.tryParse(_breakCtrl.text),
          gracePeriod: int.tryParse(_graceCtrl.text),
          overtimeThreshold: int.tryParse(_overtimeCtrl.text),
          workDays: _workDays,
          isOvernight: _isOvernight,
          isActive: _isActive,
        );
      }
      ref.invalidate(shiftsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shift saved successfully'), backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shift == null ? 'Create Shift' : 'Edit Shift')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Shift Name (e.g. Morning)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. MOR-01)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Time', border: OutlineInputBorder()),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _breakCtrl, decoration: const InputDecoration(labelText: 'Break (mins)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _graceCtrl, decoration: const InputDecoration(labelText: 'Grace Period (mins)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Work Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((day) {
                  final isSelected = _workDays.contains(day);
                  return FilterChip(
                    label: Text(day.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _workDays.add(day);
                        } else {
                          _workDays.remove(day);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withAlpha(50),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SwitchListTile(title: const Text('Is Overnight Shift?'), value: _isOvernight, onChanged: (v) => setState(() => _isOvernight = v), contentPadding: EdgeInsets.zero),
              SwitchListTile(title: const Text('Is Active?'), value: _isActive, onChanged: (v) => setState(() => _isActive = v), contentPadding: EdgeInsets.zero),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
