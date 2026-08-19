import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _runFuture = _repo.getPayrollRunDetail(widget.period);
    _payslipsFuture = _repo.getPayslipsForRun(widget.period);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          IconButton(
            icon: const Icon(Icons.download),
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
                    Text(l10n.employeesCountSuffix(run.totalEmployees), style: TextStyle(color: AppColors.grey500, fontSize: 13)),
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await _repo.exportPayroll(widget.period);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportedToPath(path)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString())), backgroundColor: AppColors.danger),
        );
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
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = widget.payslip;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.grey200),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withAlpha(26),
                    child: Text(
                      p.employeeName.isNotEmpty ? p.employeeName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.employeeName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                        Text(p.department, style: TextStyle(fontSize: 12, color: isDark ? AppColors.grey400 : AppColors.grey500)),
                      ],
                    ),
                  ),
                  Text('\$${p.netSalary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success)),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: isDark ? AppColors.grey400 : AppColors.grey400),
                ],
              ),
              if (_expanded) ...[
                Divider(height: 20, color: isDark ? AppColors.borderDark : AppColors.grey200),
                _detailRow(l10n.basicSalaryLabel, '\$${p.basicSalary.toStringAsFixed(2)}'),
                if (p.overtimePay > 0) _detailRow(l10n.overtimePayLabel, '\$${p.overtimePay.toStringAsFixed(2)}', color: AppColors.info),
                if (p.allowances > 0) _detailRow(l10n.allowancesLabel, '\$${p.allowances.toStringAsFixed(2)}'),
                if (p.otherEarnings > 0) _detailRow(l10n.otherEarningsLabel, '\$${p.otherEarnings.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _detailRow(l10n.grossSalaryLabel, '\$${p.grossSalary.toStringAsFixed(2)}', bold: true),
                const SizedBox(height: 8),
                if (p.taxDeduction > 0) _detailRow(l10n.taxDeductionLabel, '-\$${p.taxDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                if (p.insuranceDeduction > 0) _detailRow(l10n.insuranceDeductionLabel, '-\$${p.insuranceDeduction.toStringAsFixed(2)}', color: AppColors.danger),
                if (p.lateDeduction > 0) _detailRow(l10n.lateDeductionLabel, '-\$${p.lateDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                if (p.earlyLeaveDeduction > 0) _detailRow('Early Leave Deduction', '-\$${p.earlyLeaveDeduction.toStringAsFixed(2)}', color: AppColors.warning),
                if (p.otherDeductions > 0) _detailRow(l10n.otherDeductionsLabel, '-\$${p.otherDeductions.toStringAsFixed(2)}', color: AppColors.danger),
                const SizedBox(height: 4),
                _detailRow(l10n.totalDeductionsLabel, '-\$${p.totalDeductions.toStringAsFixed(2)}', color: AppColors.danger, bold: true),
                Divider(height: 16, color: isDark ? AppColors.borderDark : AppColors.grey200),
                _detailRow(l10n.netSalaryLabel, '\$${p.netSalary.toStringAsFixed(2)}', bold: true, netRow: true),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(l10n.workingDaysLabel, p.workingDays.toString(), AppColors.primary),
                    _statChip(l10n.presentLabel, p.presentDays.toString(), AppColors.success),
                    _statChip(l10n.lateLabel2, p.lateDays.toString(), AppColors.warning),
                    _statChip(l10n.otHoursLabel, p.overtimeHours.toString(), AppColors.info),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool bold = false, bool netRow = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.grey400 : AppColors.grey500, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
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
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }
}