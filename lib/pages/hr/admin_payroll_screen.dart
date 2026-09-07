import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendkh/providers/branch_switch_provider.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:open_filex/open_filex.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'formulas_screen.dart';

class AdminPayrollScreen extends ConsumerStatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  ConsumerState<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends ConsumerState<AdminPayrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchSwitch = ref.watch(branchSwitchProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.payrollManagementTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (branchSwitch.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 12),
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
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface(context),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              tabs: [Tab(text: AppLocalizations.of(context)!.runsTab), Tab(text: AppLocalizations.of(context)!.settingsTab)],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PayrollRunsTab(),
                _PayrollSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollRunsTab extends ConsumerWidget {
  const _PayrollRunsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsProvider);
    final l10n = AppLocalizations.of(context)!;

    return runsAsync.when(
      data: (items) {
        final latestRun = items.isNotEmpty ? items.first : null;
        final ytdGross = items.fold<double>(0, (sum, item) => sum + item.totalGross);
        final avgNet = items.isNotEmpty
            ? items.fold<double>(0, (sum, item) => sum + item.totalNet) / items.length
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Generate Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payroll Processing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const Text(
                          'Manage payroll runs & payslips',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showGenerateDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            l10n.generatePayrollBtn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 3 Summary KPI Cards (Matching Web) ──────────────────────────
              if (items.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _KpiMiniCard(
                        title: l10n.latestNet,
                        value: '\$${(latestRun?.totalNet ?? 0).toStringAsFixed(2)}',
                        icon: Icons.attach_money_rounded,
                        iconColor: AppColors.primary,
                        bgColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KpiMiniCard(
                        title: 'YTD Gross',
                        value: '\$${ytdGross.toStringAsFixed(2)}',
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.success,
                        bgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KpiMiniCard(
                        title: 'Avg Net',
                        value: '\$${avgNet.toStringAsFixed(2)}',
                        icon: Icons.people_alt_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFFF5F3FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Payroll Runs List ──────────────────────────────────────────
              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey300),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noPayrollRuns,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey600),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = items[i];
                    final statusColor = r.status == 'completed'
                        ? AppColors.success
                        : r.status == 'processing'
                            ? AppColors.info
                            : r.status == 'cancelled'
                                ? AppColors.danger
                                : AppColors.warning;

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Period Name, ID & Status Badge
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          r.period,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppColors.textPrimary(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${r.id}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey500,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(22),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withAlpha(60), width: 1),
                                  ),
                                  child: Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subheader: Date Range & Employee Count
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                if (r.periodStart.isNotEmpty) ...[
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.grey400),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '${r.periodStart} to ${r.periodEnd}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: AppColors.grey300)),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_alt_rounded, size: 12, color: AppColors.grey500),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${r.employeesCount}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.grey100),

                          // Financial Grid (Gross, Deductions, Net)
                          Container(
                            color: const Color(0xFFFAFAFA),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('GROSS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${r.totalGross.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey700),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DEDUCTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-\$${r.totalDeductions.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('NET TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '\$${r.totalNet.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: AppColors.grey100),

                          // Action Buttons Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (r.status == 'draft') ...[
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref.read(adminOpsRepositoryProvider).updatePayrollRunStatus(r.id, 'completed');
                                      ref.invalidate(payrollRunsProvider);
                                    },
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                                    label: const Text('Complete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.success,
                                      side: const BorderSide(color: AppColors.success, width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                FilledButton.icon(
                                  onPressed: () => context.push('/company-admin/payroll/${r.period}'),
                                  icon: const Icon(Icons.description_outlined, size: 15),
                                  label: const Text('Payslips'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () => _exportPayrollRun(context, ref, r.period),
                                  icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  tooltip: 'Export Payroll Excel',
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () => _confirmDeleteRun(context, ref, r),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEF2F2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  tooltip: l10n.deletePayrollRun,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => LoadingIndicator(message: AppLocalizations.of(context)!.loadingPayrollRuns),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(payrollRunsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context)!.tryAgain),
        ),
      ),
    );
  }

  void _exportPayrollRun(BuildContext context, WidgetRef ref, String period) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final activeBranchId = ref.read(branchSwitchProvider).activeBranchId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Exporting payroll spreadsheet...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final path = await ref.read(adminOpsRepositoryProvider).exportPayroll(period, branchId: activeBranchId);
      final fileName = path.split('/').last;

      if (context.mounted) {
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
      if (openResult.type != ResultType.done && context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _confirmDeleteRun(BuildContext context, WidgetRef ref, PayrollRunData run) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Payroll Run?'),
        content: Text(
          'Are you sure you want to delete the payroll run for ${run.period}? This will also remove all generated payslips for this period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(adminOpsRepositoryProvider).deletePayrollRun(run.id);
                ref.invalidate(payrollRunsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payroll run ${run.period} deleted.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete payroll run: $e')),
                  );
                }
              }
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }
}

class _KpiMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _KpiMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

  void _showGenerateDialog(BuildContext context, WidgetRef ref) {
  final now = DateTime.now();

  final firstDay = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);

  final periodStartCtrl = TextEditingController(
    text:
        '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}',
  );

  final periodEndCtrl = TextEditingController(
    text:
        '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}',
  );

  Future<void> pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.blue,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                AppLocalizations.of(context)!.generatePayrollBtn,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                AppLocalizations.of(context)!.generatePayrollPromptDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.grey600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: periodStartCtrl,
                readOnly: true,
                onTap: () => pickDate(periodStartCtrl),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.periodStartLabel,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: periodEndCtrl,
                readOnly: true,
                onTap: () => pickDate(periodEndCtrl),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.periodEndLabel,
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(
                          color: Colors.grey,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(adminOpsRepositoryProvider)
                              .generatePayroll(
                            periodStart: periodStartCtrl.text,
                            periodEnd: periodEndCtrl.text,
                          );

                          ref.invalidate(payrollRunsProvider);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(AppLocalizations.of(context)!.payrollGeneratedSuccess),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ $e"),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(AppLocalizations.of(context)!.generateBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PayrollSettingsTab extends ConsumerStatefulWidget {
  const _PayrollSettingsTab();

  @override
  ConsumerState<_PayrollSettingsTab> createState() => _PayrollSettingsTabState();
}

class _PayrollSettingsTabState extends ConsumerState<_PayrollSettingsTab> {
  final _periodCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _currencySymbolCtrl = TextEditingController();
  final _startDayCtrl = TextEditingController();
  final _workingDaysCtrl = TextEditingController(); // fixed_working_days
  
  final _otThresholdCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController(); // regular_ot_multiplier
  final _weekendOtCtrl = TextEditingController(); // rest_day_ot_multiplier
  final _pubHolidayOtCtrl = TextEditingController(); // public_holiday_ot_multiplier
  final _compHolidayOtCtrl = TextEditingController(); // company_holiday_ot_multiplier
  
  final _graceMinutesCtrl = TextEditingController(); // late_grace_period_minutes
  final _lateDeductionCtrl = TextEditingController(); // late_deduction_rate
  
  final _earlyLeaveGraceCtrl = TextEditingController();
  final _earlyLeaveRateCtrl = TextEditingController();

  final _preShiftOtCtrl = TextEditingController();
  final _maxPreShiftCtrl = TextEditingController();

  final _halfDayHoursCtrl = TextEditingController();
  final _halfDayPctCtrl = TextEditingController();

  final _taxRateCtrl = TextEditingController();
  final _insuranceRateCtrl = TextEditingController();

  bool _otEnabled = false;
  bool _lateEnabled = false;
  bool _taxEnabled = false;
  bool _insuranceEnabled = false;
  
  String _lateCalcMethod = 'per_minute';
  String _earlyLeaveDedType = 'per_minute';
  String _earlyClockInPolicy = 'ignore';
  String _workingDaysType = 'calendar_days';
  
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(payrollSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (!_initialized) {
          _periodCtrl.text = settings.payrollPeriod;
          _currencyCtrl.text = settings.currency;
          _currencySymbolCtrl.text = settings.currencySymbol;
          _startDayCtrl.text = settings.payrollStartDay.toString();
          
          _otThresholdCtrl.text = settings.overtimeThreshold.toString();
          _otMultiplierCtrl.text = settings.regularOtMultiplier.toString();
          _weekendOtCtrl.text = settings.restDayOtMultiplier.toString();
          _pubHolidayOtCtrl.text = settings.publicHolidayOtMultiplier.toString();
          _compHolidayOtCtrl.text = settings.companyHolidayOtMultiplier.toString();
          
          _graceMinutesCtrl.text = settings.lateGracePeriodMinutes.toString();
          _lateDeductionCtrl.text = settings.lateDeductionRate.toString();
          
          _earlyLeaveGraceCtrl.text = settings.earlyLeaveGracePeriodMinutes.toString();
          _earlyLeaveRateCtrl.text = settings.earlyLeaveDeductionRate.toString();
          _earlyLeaveDedType = settings.earlyLeaveDeductionType;
          
          _preShiftOtCtrl.text = settings.preShiftOtMultiplier.toString();
          _maxPreShiftCtrl.text = settings.maxPreShiftOtMinutes.toString();
          _earlyClockInPolicy = settings.earlyClockInPolicy;

          _halfDayHoursCtrl.text = settings.halfDayHours.toString();
          _halfDayPctCtrl.text = settings.halfDayDeductionPercentage.toString();

          _taxEnabled = settings.taxEnabled;
          _taxRateCtrl.text = settings.taxRatePercentage.toString();
          _insuranceEnabled = settings.insuranceEnabled;
          _insuranceRateCtrl.text = settings.insuranceRatePercentage.toString();
          
          _workingDaysType = settings.workingDaysType;
          _workingDaysCtrl.text = settings.fixedWorkingDays.toString();
          
          _otEnabled = settings.overtimeEnabled;
          _lateEnabled = settings.lateDeductionEnabled;
          _lateCalcMethod = settings.lateDeductionType;
          
          _initialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF047857)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.calculate, color: Colors.white, size: 32),
                  title: Text(l10n.formulasHandbookTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(l10n.formulasHandbookDesc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () async {
                    final s = await ref.read(companyFormulasProvider.future);
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FormulasScreen(settings: s)));
                    }
                  },
                ),
              ),
              _sectionHeader(l10n.generalSettingsTitle),
              const SizedBox(height: 12),
              _dropdownField(
                context: context,
                label: l10n.payrollPeriodLabel,
                value: _periodCtrl.text,
                items: const ['weekly', 'bi_weekly', 'monthly'],
                onChanged: (v) => setState(() => _periodCtrl.text = v),
              ),
              const SizedBox(height: 12),
              _textField(_startDayCtrl, l10n.payrollStartDayLabel, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _dropdownField(
                context: context,
                label: l10n.workingDaysCalcTypeLabel,
                value: _workingDaysType,
                items: const ['calendar_days', 'calendar_minus_holidays', 'fixed'],
                onChanged: (v) => setState(() => _workingDaysType = v),
              ),
              if (_workingDaysType == 'fixed') ...[
                const SizedBox(height: 12),
                _textField(_workingDaysCtrl, l10n.fixedWorkingDaysLabel, keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 12),
              _textField(_currencyCtrl, l10n.currencyLabel),
              const SizedBox(height: 12),
              _textField(_currencySymbolCtrl, l10n.currencySymbolLabel),

              const SizedBox(height: 28),
              _sectionHeader(l10n.overtimeSettingsTitle),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.enableOvertimePayLabel),
                value: _otEnabled,
                onChanged: (val) => setState(() => _otEnabled = val),
              ),
              if (_otEnabled) ...[
                const SizedBox(height: 8),
                _textField(_otThresholdCtrl, l10n.overtimeThresholdLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_otMultiplierCtrl, l10n.regularOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_weekendOtCtrl, l10n.restDayOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_pubHolidayOtCtrl, l10n.publicHolidayOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_compHolidayOtCtrl, l10n.companyHolidayOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],

              const SizedBox(height: 28),
              _sectionHeader(l10n.lateDeductionSettingsTitle),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.enableLateDeductionsLabel),
                value: _lateEnabled,
                onChanged: (val) => setState(() => _lateEnabled = val),
              ),
              if (_lateEnabled) ...[
                const SizedBox(height: 8),
                _textField(_graceMinutesCtrl, l10n.gracePeriodMinutesLabel, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dropdownField(
                  context: context,
                  label: l10n.calculationMethodLabel,
                  value: _lateCalcMethod,
                  items: const ['per_minute', 'fixed_amount', 'half_day'],
                  onChanged: (v) {
                    setState(() {
                      _lateCalcMethod = v;
                      final currentRate = double.tryParse(_lateDeductionCtrl.text) ?? 1.0;
                      if (v == 'per_minute' && currentRate > 5) {
                        _lateDeductionCtrl.text = '1.0';
                      } else if (v == 'fixed_amount' && currentRate <= 2) {
                        _lateDeductionCtrl.text = '5.0';
                      }
                    });
                  },
                ),
                if (_lateCalcMethod != 'half_day') ...[
                  const SizedBox(height: 12),
                  _textField(
                    _lateDeductionCtrl,
                    _lateCalcMethod == 'fixed_amount' ? l10n.fixedPenaltyAmountLabel : l10n.perMinuteMultiplierLabel,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ],

              const SizedBox(height: 28),
              _sectionHeader(l10n.earlyLeavePenaltiesTitle),
              const SizedBox(height: 12),
              _textField(_earlyLeaveGraceCtrl, l10n.earlyLeaveGraceLabel, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _dropdownField(
                context: context,
                label: l10n.deductionTypeLabel,
                value: _earlyLeaveDedType,
                items: const ['per_minute', 'fixed_amount', 'half_day'],
                onChanged: (v) {
                  setState(() {
                    _earlyLeaveDedType = v;
                    final currentRate = double.tryParse(_earlyLeaveRateCtrl.text) ?? 1.0;
                    if (v == 'per_minute' && currentRate > 5) {
                      _earlyLeaveRateCtrl.text = '1.0';
                    } else if (v == 'fixed_amount' && currentRate <= 2) {
                      _earlyLeaveRateCtrl.text = '5.0';
                    }
                  });
                },
              ),
              if (_earlyLeaveDedType != 'half_day') ...[
                const SizedBox(height: 12),
                _textField(
                  _earlyLeaveRateCtrl,
                  _earlyLeaveDedType == 'fixed_amount' ? l10n.fixedPenaltyAmountLabel : l10n.perMinuteMultiplierLabel,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],

              const SizedBox(height: 28),
              _sectionHeader(l10n.preShiftEarlyClockInTitle),
              const SizedBox(height: 12),
              _dropdownField(
                context: context,
                label: l10n.earlyClockInPolicyLabel,
                value: _earlyClockInPolicy,
                items: const ['ignore', 'treat_as_ot', 'paid_outside'],
                onChanged: (v) => setState(() => _earlyClockInPolicy = v),
              ),
              if (_earlyClockInPolicy == 'treat_as_ot') ...[
                const SizedBox(height: 12),
                _textField(_preShiftOtCtrl, l10n.preShiftOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_maxPreShiftCtrl, l10n.maxAllowedEarlyMinutesLabel, keyboardType: TextInputType.number),
              ],

              const SizedBox(height: 28),
              _sectionHeader(l10n.halfDaySettingsTitle),
              const SizedBox(height: 12),
              _textField(_halfDayHoursCtrl, l10n.halfDayMinHoursLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _textField(_halfDayPctCtrl, l10n.halfDayDeductionPctLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),

              const SizedBox(height: 28),
              _sectionHeader('Tax & NSSF / Social Security'),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.enableTaxOnSalary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.deductIncomeTaxDesc, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                value: _taxEnabled,
                onChanged: (v) => setState(() => _taxEnabled = v),
              ),
              if (_taxEnabled) ...[
                const SizedBox(height: 8),
                _textField(_taxRateCtrl, 'Tax Rate Percentage (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.enableNssfInsurance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.deductSocialSecurityDesc, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                value: _insuranceEnabled,
                onChanged: (v) => setState(() => _insuranceEnabled = v),
              ),
              if (_insuranceEnabled) ...[
                const SizedBox(height: 8),
                _textField(_insuranceRateCtrl, 'NSSF / Insurance Rate (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.saveSettingsBtn, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => LoadingIndicator(message: AppLocalizations.of(context)!.loadingSettings),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(payrollSettingsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context)!.tryAgain),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await ref.read(adminOpsRepositoryProvider).updatePayrollSettings({
        'payroll_period': _periodCtrl.text,
        'payroll_start_day': int.tryParse(_startDayCtrl.text) ?? 1,
        'working_days_type': _workingDaysType,
        'fixed_working_days': int.tryParse(_workingDaysCtrl.text) ?? 22,
        'currency': _currencyCtrl.text,
        'currency_symbol': _currencySymbolCtrl.text,
        
        'overtime_enabled': _otEnabled,
        'overtime_threshold': double.tryParse(_otThresholdCtrl.text) ?? 1.0,
        'regular_ot_multiplier': double.tryParse(_otMultiplierCtrl.text) ?? 1.5,
        'rest_day_ot_multiplier': double.tryParse(_weekendOtCtrl.text) ?? 2.0,
        'public_holiday_ot_multiplier': double.tryParse(_pubHolidayOtCtrl.text) ?? 2.0,
        'company_holiday_ot_multiplier': double.tryParse(_compHolidayOtCtrl.text) ?? 1.5,
        
        'late_deduction_enabled': _lateEnabled,
        'late_grace_period_minutes': int.tryParse(_graceMinutesCtrl.text) ?? 15,
        'late_deduction_type': _lateCalcMethod,
        'late_deduction_rate': double.tryParse(_lateDeductionCtrl.text) ?? 0,
        
        'early_leave_grace_period_minutes': int.tryParse(_earlyLeaveGraceCtrl.text) ?? 0,
        'early_leave_deduction_type': _earlyLeaveDedType,
        'early_leave_deduction_rate': double.tryParse(_earlyLeaveRateCtrl.text) ?? 0,
        
        'early_clock_in_policy': _earlyClockInPolicy,
        'pre_shift_ot_multiplier': double.tryParse(_preShiftOtCtrl.text) ?? 1.25,
        'max_pre_shift_ot_minutes': int.tryParse(_maxPreShiftCtrl.text) ?? 120,

        'half_day_hours': double.tryParse(_halfDayHoursCtrl.text) ?? 4.0,
        'half_day_deduction_percentage': double.tryParse(_halfDayPctCtrl.text) ?? 50.0,

        'tax_enabled': _taxEnabled,
        'tax_rate_percentage': double.tryParse(_taxRateCtrl.text) ?? 0.0,
        'insurance_enabled': _insuranceEnabled,
        'insurance_rate_percentage': double.tryParse(_insuranceRateCtrl.text) ?? 0.0,
      });
      ref.invalidate(payrollSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.settingsSavedSuccess), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)));
  }

  Widget _textField(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: keyboardType,
    );
  }

  Widget _dropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(_formatLabel(context, i)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  String _formatLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'weekly': return l10n.weeklyLabel;
      case 'bi_weekly': return l10n.biWeeklyLabel;
      case 'monthly': return l10n.monthlyLabel;
      case 'calendar_days': return l10n.calendarDaysLabel;
      case 'calendar_minus_holidays': return l10n.calendarMinusHolidaysLabel;
      case 'fixed': return l10n.fixedDaysLabel;
      case 'treat_as_ot': return l10n.treatAsOvertimeLabel;
      case 'paid_outside': return l10n.paidOutsideLabel;
      case 'flat': return l10n.flatAmountLabel;
      case 'hourly': return l10n.hourlyRateLabel;
      case 'per_minute': return l10n.perMinuteRateLabel;
      case 'half_day': return l10n.halfDayDeductionLabel;
      case 'ignore': return l10n.ignoreNoExtraPayLabel;
      default: return key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
}
