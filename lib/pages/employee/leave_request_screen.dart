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
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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

  Future<void> _submitRequest(AppLocalizations l10n) async {
    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectLeaveType), backgroundColor: AppColors.danger),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterLeaveReason), backgroundColor: AppColors.danger),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final employeeIdStr = authState.employeeId;
    if (employeeIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noEmployeeProfile), backgroundColor: AppColors.danger),
      );
      return;
    }

    final employeeId = int.tryParse(employeeIdStr);
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidEmployeeId), backgroundColor: AppColors.danger),
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
          SnackBar(content: Text(l10n.leaveRequestSubmitted), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String msg = l10n.failedToSubmitLeave;
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
    final leaveTypesAsync = ref.watch(leaveTypesProvider);
    final leaveBalancesAsync = ref.watch(leaveBalancesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          l10n.requestLeave,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      body: _isSubmitting
          ? LoadingIndicator(message: l10n.submittingLeave)
          : leaveTypesAsync.when(
              data: (leaveTypes) {
                if (leaveTypes.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noLeaveTypesConfigured,
                      style: const TextStyle(color: AppColors.grey500),
                    ),
                  );
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
                      Text(
                        l10n.leaveTypeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedLeaveTypeId ?? leaveTypes.first.id,
                        dropdownColor: AppColors.surface(context),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.category),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDarkElevated
                              : AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border(context)),
                          ),
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
                                color: isDark
                                    ? (isLow
                                        ? AppColors.warning.withValues(alpha: 0.15)
                                        : AppColors.success.withValues(alpha: 0.15))
                                    : (isLow ? AppColors.warningLight : AppColors.successLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLow
                                      ? (isDark ? AppColors.warning.withValues(alpha: 0.5) : AppColors.warning)
                                      : (isDark ? AppColors.success.withValues(alpha: 0.5) : AppColors.success),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(isLow ? Icons.warning_rounded : Icons.check_circle_rounded,
                                      size: 18, color: isLow ? AppColors.warning : AppColors.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text: '${balance.typeName}${l10n.balanceLabel}',
                                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.grey700),
                                        children: [
                                          TextSpan(
                                            text: remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1) + l10n.daysRemaining,
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
                                color: isDark ? AppColors.warning.withValues(alpha: 0.15) : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppColors.warning.withValues(alpha: 0.5) : AppColors.warning),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                                  const SizedBox(width: 8),
                                  Text(l10n.noBalanceRecord, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.grey700)),
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
                                Text(
                                  l10n.startDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                                      border: Border.all(color: AppColors.border(context)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_startDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary(context),
                                          ),
                                        ),
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
                                Text(
                                  l10n.endDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(false),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                                      border: Border.all(color: AppColors.border(context)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_endDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary(context),
                                          ),
                                        ),
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
                      SizedBox(height: 16),

                      // Half Day Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.grey200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.requestHalfDay,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                                  ),
                                ),
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
                              Divider(height: 1, color: AppColors.border(context)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _halfDayPeriod = 'morning'),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: _halfDayPeriod == 'morning'
                                              ? AppColors.primary.withAlpha(20)
                                              : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey50),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _halfDayPeriod == 'morning'
                                                ? AppColors.primary
                                                : (isDark ? AppColors.borderDark : AppColors.grey300),
                                            width: _halfDayPeriod == 'morning' ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _halfDayPeriod == 'morning' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                              size: 16,
                                              color: _halfDayPeriod == 'morning' ? AppColors.primary : AppColors.grey500,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  l10n.morning,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: _halfDayPeriod == 'morning' ? FontWeight.bold : FontWeight.w500,
                                                    color: _halfDayPeriod == 'morning' ? AppColors.primary : (isDark ? AppColors.grey300 : AppColors.grey700),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _halfDayPeriod = 'afternoon'),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: _halfDayPeriod == 'afternoon'
                                              ? AppColors.primary.withAlpha(20)
                                              : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey50),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _halfDayPeriod == 'afternoon'
                                                ? AppColors.primary
                                                : (isDark ? AppColors.borderDark : AppColors.grey300),
                                            width: _halfDayPeriod == 'afternoon' ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _halfDayPeriod == 'afternoon' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                              size: 16,
                                              color: _halfDayPeriod == 'afternoon' ? AppColors.primary : AppColors.grey500,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  l10n.afternoon,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: _halfDayPeriod == 'afternoon' ? FontWeight.bold : FontWeight.w500,
                                                    color: _halfDayPeriod == 'afternoon' ? AppColors.primary : (isDark ? AppColors.grey300 : AppColors.grey700),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      Text(
                        l10n.reason,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        style: TextStyle(color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: l10n.describeLeaveReason,
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
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
                      const SizedBox(height: 16),

                      // Attachment
                      Text(
                        l10n.attachmentOptional,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
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
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
                            border: Border.all(
                              color: _attachment != null
                                  ? AppColors.primary
                                  : AppColors.border(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.attach_file, color: _attachment != null ? AppColors.primary : AppColors.grey500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _attachment?.name ?? l10n.tapToSelectFile,
                                  style: TextStyle(
                                    color: _attachment != null
                                        ? (isDark ? Colors.white : AppColors.grey800)
                                        : AppColors.grey500,
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
                        onPressed: () => _submitRequest(l10n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.submitRequest, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                );
              },
              loading: () => LoadingIndicator(message: l10n.loadingLeaveTypes),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    Text(l10n.failedToLoadLeaveTypes),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(leaveTypesProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}