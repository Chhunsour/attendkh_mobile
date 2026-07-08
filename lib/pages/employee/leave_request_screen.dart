import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/leave_provider.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
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
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(date)) {
            _endDate = date.add(const Duration(days: 1));
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
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
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
    final balancesAsync = ref.watch(leaveBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: _isSubmitting
          ? const LoadingIndicator(message: 'Submitting leave request...')
          : balancesAsync.when(
              data: (balances) {
                if (balances.isEmpty) {
                  return const Center(child: Text('No leave types configured for your company.', style: TextStyle(color: AppColors.grey500)));
                }

                // Default selection
                if (_selectedLeaveTypeId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedLeaveTypeId = balances.first.leaveTypeId;
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
                        initialValue: _selectedLeaveTypeId ?? balances.first.leaveTypeId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: balances.map((b) {
                          return DropdownMenuItem<int>(
                            value: b.leaveTypeId,
                            child: Text('${b.typeName} (${b.remaining.toStringAsFixed(1)} days left)'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedLeaveTypeId = v),
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _pickDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18, color: AppColors.grey500),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontSize: 14)),
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
                                const Text('End Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey700)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _pickDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18, color: AppColors.grey500),
                                        const SizedBox(width: 8),
                                        Text(DateFormat('dd/MM/yyyy').format(_endDate), style: const TextStyle(fontSize: 14)),
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
              loading: () => const LoadingIndicator(message: 'Loading leave balances...'),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    const Text('Failed to load leave types'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(leaveBalancesProvider),
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