import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class AdminPayrollDetailScreen extends ConsumerStatefulWidget {
  final String period;
  const AdminPayrollDetailScreen({super.key, required this.period});

  @override
  ConsumerState<AdminPayrollDetailScreen> createState() => _AdminPayrollDetailScreenState();
}

class _AdminPayrollDetailScreenState extends ConsumerState<AdminPayrollDetailScreen> {
  late Future<PayrollRunDetailData> _runFuture;
  late Future<List<AdminPayslipDetailData>> _payslipsFuture;
  final _repo = AdminOperationsRepository();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final activeBranchId = ref.read(branchSwitchProvider).activeBranchId;
    _runFuture = _repo.getPayrollRunDetail(widget.period);
    _payslipsFuture = _repo.getPayslipsForRun(widget.period, branchId: activeBranchId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branchSwitch = ref.watch(branchSwitchProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.payrollDetailTitle(widget.period),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (branchSwitch.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          branchSwitch.activeBranchName ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: l10n.exportToExcelTooltip,
              onPressed: _exportPayroll,
            ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_runFuture, _payslipsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingIndicator(message: l10n.loadingPayslips);
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.payrollDetailError(snapshot.error.toString()), style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _loadData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final run = (snapshot.data as List).first as PayrollRunDetailData;
          final payslips = (snapshot.data as List).last as List<AdminPayslipDetailData>;

          return Column(
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(label: l10n.totalGrossLabel, value: '\$${run.totalGross.toStringAsFixed(0)}', color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: l10n.deductionsLabel, value: '\$${run.totalDeductions.toStringAsFixed(0)}', color: AppColors.danger)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: l10n.netPayLabel, value: '\$${run.totalNet.toStringAsFixed(0)}', color: AppColors.success)),
                  ],
                ),
              ),
              // Status & employee count row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: run.status == 'completed' ? AppColors.success.withAlpha(26) : AppColors.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        run.status.substring(0, 1).toUpperCase() + run.status.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: run.status == 'completed' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(l10n.employeesCountSuffix(run.totalEmployees), style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              // Payslip list
              Expanded(
                child: payslips.isEmpty
                    ? Center(child: Text(l10n.noPayslipsFound, style: const TextStyle(color: AppColors.grey400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: payslips.length,
                        itemBuilder: (context, i) {
                          final p = payslips[i];
                          return _PayslipCard(payslip: p);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportPayroll() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final activeBranchId = ref.read(branchSwitchProvider).activeBranchId;
      final path = await _repo.exportPayroll(widget.period, branchId: activeBranchId);
      final fileName = path.split('/').last;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportedToPath(fileName)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(path),
            ),
          ),
        );
      }

      final openResult = await OpenFilex.open(path);
      if (openResult.type != ResultType.done && mounted) {
        String msg = 'Saved to: $path';
        if (openResult.type == ResultType.noAppToOpen) {
          msg = 'File saved to Downloads folder ($fileName).\nPlease install Microsoft Excel or Google Sheets to view .xlsx files.';
        } else if (openResult.message.isNotEmpty) {
          msg = 'Saved to: $path\n${openResult.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PayslipCard extends StatefulWidget {
  final AdminPayslipDetailData payslip;
  const _PayslipCard({required this.payslip});

  @override
  State<_PayslipCard> createState() => _PayslipCardState();
}

class _PayslipCardState extends State<_PayslipCard> {
  bool _expanded = false;

  Widget _buildAvatar(AdminPayslipDetailData p, bool isDark) {
    if (p.photoUrl != null && p.photoUrl!.isNotEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.grey200, width: 1),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: p.photoUrl!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _buildInitialsAvatar(p, isDark),
            placeholder: (context, url) => _buildInitialsAvatar(p, isDark),
          ),
        ),
      );
    }
    return _buildInitialsAvatar(p, isDark);
  }

  Widget _buildInitialsAvatar(AdminPayslipDetailData p, bool isDark) {
    final initial = p.employeeName.trim().isNotEmpty
        ? p.employeeName.trim()[0].toUpperCase()
        : 'E';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.payslip;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.grey200),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  _buildAvatar(p, isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Khmer Name
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.employeeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.grey900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.khmerName != null && p.khmerName!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '(${p.khmerName})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Employee code & Department / Position
                        Row(
                          children: [
                            if (p.employeeCode.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.grey300, width: 0.5),
                                ),
                                child: Text(
                                  p.employeeCode,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                p.position.isNotEmpty
                                    ? (p.department.isNotEmpty ? '${p.position} • ${p.department}' : p.position)
                                    : (p.department.isNotEmpty ? p.department : 'General Staff'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${p.netSalary.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.success),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.grey400 : AppColors.grey400,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                Divider(height: 22, color: isDark ? AppColors.borderDark : AppColors.grey200),
                
                // Earnings Breakdown
                _sectionSubHeader('EARNINGS & ALLOWANCES', AppColors.primary),
                const SizedBox(height: 6),
                _detailRow(l10n.basicSalaryLabel, '\$${p.basicSalary.toStringAsFixed(2)}'),
                if (p.overtimePay > 0 || p.overtimeHours > 0)
                  _detailRow(
                    '${l10n.overtimePayLabel} (${p.overtimeHours}h)',
                    '\$${p.overtimePay.toStringAsFixed(2)}',
                    color: AppColors.info,
                  ),
                if (p.allowances > 0)
                  _detailRow(l10n.allowancesLabel, '\$${p.allowances.toStringAsFixed(2)}'),
                if (p.leaveEncashmentAmount > 0)
                  _detailRow('Leave Encashment', '\$${p.leaveEncashmentAmount.toStringAsFixed(2)}', color: AppColors.info),
                if (p.otherEarnings > 0)
                  _detailRow(l10n.otherEarningsLabel, '\$${p.otherEarnings.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _detailRow(l10n.grossSalaryLabel, '\$${p.grossSalary.toStringAsFixed(2)}', bold: true),

                const SizedBox(height: 12),
                // Deductions Breakdown
                _sectionSubHeader('DEDUCTIONS & TAX', AppColors.danger),
                const SizedBox(height: 6),
                if (p.taxDeduction > 0)
                  _detailRow(l10n.taxDeductionLabel, '-\$${p.taxDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                if (p.insuranceDeduction > 0)
                  _detailRow(l10n.insuranceDeductionLabel, '-\$${p.insuranceDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                if (p.lateDeduction > 0 || p.lateDays > 0)
                  _detailRow(
                    '${l10n.lateDeductionLabel} (${p.lateDays}x${p.lateMinutes > 0 ? ', ${p.lateMinutes}m' : ''})',
                    '-\$${p.lateDeduction.toStringAsFixed(2)}',
                    color: AppColors.warning,
                  ),
                if (p.earlyLeaveDeduction > 0 || p.earlyLeaveDays > 0)
                  _detailRow(
                    'Early Leave (${p.earlyLeaveDays}x${p.earlyLeaveMinutes > 0 ? ', ${p.earlyLeaveMinutes}m' : ''})',
                    '-\$${p.earlyLeaveDeduction.toStringAsFixed(2)}',
                    color: AppColors.warning,
                  ),
                if (p.unpaidLeaveDeduction > 0)
                  _detailRow('Unpaid Leave Deduction', '-\$${p.unpaidLeaveDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                if (p.otherDeductions > 0)
                  _detailRow(l10n.otherDeductionsLabel, '-\$${p.otherDeductions.toStringAsFixed(2)}', color: AppColors.danger),
                const SizedBox(height: 4),
                _detailRow(l10n.totalDeductionsLabel, '-\$${p.totalDeductions.toStringAsFixed(2)}', color: AppColors.danger, bold: true),

                Divider(height: 20, color: isDark ? AppColors.borderDark : AppColors.grey200),
                
                // Net Take-Home Highlight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: _detailRow(l10n.netSalaryLabel, '\$${p.netSalary.toStringAsFixed(2)}', bold: true, netRow: true, color: AppColors.success),
                ),

                const SizedBox(height: 12),
                // Attendance Summary Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(l10n.workingDaysLabel, p.workingDays.toString(), AppColors.primary),
                    _statChip(l10n.presentLabel, p.presentDays.toString(), AppColors.success),
                    _statChip(l10n.lateLabel2, p.lateDays > 0 ? '${p.lateDays} (${p.lateMinutes}m)' : '0', AppColors.warning),
                    _statChip(l10n.otHoursLabel, '${p.overtimeHours}h', AppColors.info),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionSubHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false, bool netRow = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: netRow ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? (isDark ? Colors.white : AppColors.grey800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }
}