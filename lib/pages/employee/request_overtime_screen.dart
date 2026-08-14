import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/overtime_providers.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/services/overtime_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/components/custom_time_picker.dart';

class RequestOvertimeScreen extends ConsumerStatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  ConsumerState<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends ConsumerState<RequestOvertimeScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  bool _isLoadingShift = false;
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchShiftForSelectedDate();
    });
  }

  Future<void> _fetchShiftForSelectedDate() async {
    setState(() => _isLoadingShift = true);
    try {
      final repo = ref.read(overtimeRepositoryProvider);
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final data = await repo.getShiftForDate(dateFormatter.format(_selectedDate));
      
      if (data['is_working'] == true && data['start_time'] != null && data['end_time'] != null) {
        final startParts = (data['start_time'] as String).split(':');
        final endParts = (data['end_time'] as String).split(':');
        setState(() {
          _shiftStart = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
          _shiftEnd = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
        });
      } else {
        setState(() {
          _shiftStart = null;
          _shiftEnd = null;
        });
      }
    } catch (e) {
      // Ignore errors for shift fetching
    } finally {
      if (mounted) setState(() => _isLoadingShift = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showCustomDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _fetchShiftForSelectedDate();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showCustomTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      disabledStart: _shiftStart,
      disabledEnd: _shiftEnd,
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

  Future<void> _submitRequest(AppLocalizations l10n) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fieldRequired), backgroundColor: AppColors.danger),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employee profile found'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(overtimeRepositoryProvider);
      final dateFormatter = DateFormat('yyyy-MM-dd');

      final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      await repo.submitOvertimeRequest(
        date: dateFormatter.format(_selectedDate),
        startTime: startStr,
        endTime: endStr,
        reason: reason,
      );

      ref.invalidate(overtimeRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Overtime request submitted'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = 'Failed to submit request';
      if (e is AppException) {
        msg = e.message;
      } else {
        msg = e.toString().replaceAll('Exception: ', '');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Overtime')),
      body: _isSubmitting
          ? LoadingIndicator(message: 'Submitting request...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16, color: AppColors.grey900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoadingShift)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Loading shift schedule...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
                  else if (_shiftStart != null && _shiftEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Shift: ${_shiftStart!.format(context)} - ${_shiftEnd!.format(context)}', 
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _pickTime(true),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  border: Border.all(color: AppColors.grey300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(_startTime.format(context), style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _pickTime(false),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  border: Border.all(color: AppColors.grey300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(_endTime.format(context), style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe why overtime is needed...',
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _submitRequest(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
