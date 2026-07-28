// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  int? _selectedLeaveTypeId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isHalfDay = false;
  String _halfDayPeriod = 'morning';
  PlatformFile? _attachment;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showCustomDatePicker(
      context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_isHalfDay || _endDate.isBefore(date)) {
            _endDate = date;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for the leave'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final employeeIdStr = authState.employeeId;
    if (employeeIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employee profile associated with this account'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final employeeId = int.tryParse(employeeIdStr);
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid employee ID configuration'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(leaveRepositoryProvider);
      final formatter = DateFormat('yyyy-MM-dd');

      await repo.submitRequest(
        employeeId: employeeId,
        leaveTypeId: _selectedLeaveTypeId!,
        startDate: formatter.format(_startDate),
        endDate: formatter.format(_endDate),
        reason: reason,
        isHalfDay: _isHalfDay,
        halfDayPeriod: _halfDayPeriod,
        attachment: _attachment,
      );

      // Invalidate providers so screens reload data
      ref.invalidate(leaveRequestsProvider);
      ref.invalidate(leaveBalancesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Leave request submitted successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = 'Failed to submit leave request';
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
    final leaveTypesAsync = ref.watch(leaveTypesProvider);
    final leaveBalancesAsync = ref.watch(leaveBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: _isSubmitting
          ? const LoadingIndicator(message: 'Submitting leave request...')
          : leaveTypesAsync.when(
              data: (leaveTypes) {
                if (leaveTypes.isEmpty) {
                  return const Center(child: Text('No leave types configured for your company.', style: TextStyle(color: AppColors.grey500)));
                }

                // Default selection
                if (_selectedLeaveTypeId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedLeaveTypeId = leaveTypes.first.id;
                      });
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Leave Type
                      const Text('Leave Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedLeaveTypeId ?? leaveTypes.first.id,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: leaveTypes.map((lt) {
                          return DropdownMenuItem<int>(
                            value: lt.id,
                            child: Text(lt.name),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedLeaveTypeId = v),
                      ),
                      const SizedBox(height: 12),

                      // Balance Info Card
                      leaveBalancesAsync.when(
                        data: (balances) {
                          final sel = _selectedLeaveTypeId;
                          if (sel == null) return const SizedBox.shrink();
                          try {
                            final balance = balances.firstWhere((b) => b.leaveTypeId == sel);
                            final remaining = balance.remaining;
                            final isLow = remaining <= 1;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isLow ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isLow ? AppColors.warning : AppColors.success),
                              ),
                              child: Row(
                                children: [
                                  Icon(isLow ? Icons.warning_rounded : Icons.check_circle_rounded,
                                      size: 18, color: isLow ? AppColors.warning : AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: '${balance.typeName} balance: ',
                                        style: const TextStyle(fontSize: 13, color: AppColors.grey700),
                                        children: [
                                          TextSpan(
                                            text: '${remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1)} days remaining',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isLow ? AppColors.warning : AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } catch (_) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warning),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                                  SizedBox(width: 8),
                                  Text('No balance record found for this leave type.', style: TextStyle(fontSize: 13, color: AppColors.grey700)),
                                ],
                              ),
                            );
                          }
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd MMM yyyy').format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('End Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd MMM yyyy').format(_endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Half Day Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Request Half Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                                Switch(
                                  value: _isHalfDay,
                                  onChanged: (v) {
                                    setState(() {
                                      _isHalfDay = v;
                                      if (v) _endDate = _startDate;
                                    });
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                            if (_isHalfDay) ...[
                              const Divider(height: 1),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Morning', style: TextStyle(fontSize: 14)),
                                      value: 'morning',
                                      groupValue: _halfDayPeriod,
                                      onChanged: (v) => setState(() => _halfDayPeriod = v!),
                                      activeColor: AppColors.primary,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Afternoon', style: TextStyle(fontSize: 14)),
                                      value: 'afternoon',
                                      groupValue: _halfDayPeriod,
                                      onChanged: (v) => setState(() => _halfDayPeriod = v!),
                                      activeColor: AppColors.primary,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      const Text('Reason', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe your reason for leave...',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attachment
                      const Text('Attachment (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'png', 'pdf'],
                          );
                          if (result != null) {
                            setState(() => _attachment = result.files.first);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _attachment != null ? AppColors.primary : AppColors.grey300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.attach_file, color: _attachment != null ? AppColors.primary : AppColors.grey500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _attachment?.name ?? 'Tap to select file (PDF, JPG, PNG)',
                                  style: TextStyle(
                                    color: _attachment != null ? AppColors.grey800 : AppColors.grey500,
                                    fontWeight: _attachment != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_attachment != null)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: AppColors.danger),
                                  onPressed: () => setState(() => _attachment = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: 'Loading leave types...'),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    const Text('Failed to load leave types'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(leaveTypesProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}