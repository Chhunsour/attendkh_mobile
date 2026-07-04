import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

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
    return Column(
      children: [
        Container(
          color: AppColors.surfaceLight,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'Runs'), Tab(text: 'Settings')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PayrollRunsTab(),
              _PayrollSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayrollRunsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showGenerateDialog(context, ref),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Generate Payroll'),
          ),
        ),
        Expanded(
          child: runsAsync.when(
            data: (items) => items.isEmpty
                ? const Center(child: Text('No payroll runs', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      final statusColor = r.status == 'completed' ? AppColors.success : r.status == 'processing' ? AppColors.info : AppColors.warning;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                        child: Row(
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.receipt_long, color: statusColor, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.period, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('${r.employeesCount} employees', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('\$${r.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(r.status.substring(0, 1).toUpperCase() + r.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingIndicator(message: 'Loading payroll runs...'),
            error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(payrollRunsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
          ),
        ),
      ],
    );
  }

  void _showGenerateDialog(BuildContext context, WidgetRef ref) {
    final periodController = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Payroll'),
        content: TextField(controller: periodController, decoration: const InputDecoration(labelText: 'Period (YYYY-MM)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            try {
              await AdminOperationsRepository().generatePayroll(period: periodController.text);
              ref.invalidate(payrollRunsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Payroll generated'), backgroundColor: AppColors.success));
            } catch (e) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Generate')),
        ],
      ),
    );
  }
}

class _PayrollSettingsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PayrollSettingsTab> createState() => _PayrollSettingsTabState();
}

class _PayrollSettingsTabState extends ConsumerState<_PayrollSettingsTab> {
  final _periodCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController();
  final _lateDeductionCtrl = TextEditingController();
  bool _otEnabled = false;
  bool _lateEnabled = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(payrollSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (!_initialized) {
          _periodCtrl.text = settings.payrollPeriod;
          _currencyCtrl.text = settings.currency;
          _otMultiplierCtrl.text = settings.overtimeMultiplier.toString();
          _lateDeductionCtrl.text = settings.lateDeductionPerMinute.toString();
          _otEnabled = settings.overtimeEnabled;
          _lateEnabled = settings.lateDeductionEnabled;
          _initialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('General Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _periodCtrl, decoration: const InputDecoration(labelText: 'Payroll Period (e.g. monthly)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency (e.g. USD)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              const Text('Overtime Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable Overtime Pay'),
                value: _otEnabled,
                onChanged: (val) => setState(() => _otEnabled = val),
              ),
              if (_otEnabled) ...[
                const SizedBox(height: 12),
                TextField(controller: _otMultiplierCtrl, decoration: const InputDecoration(labelText: 'Overtime Multiplier', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
              const SizedBox(height: 24),
              const Text('Late Deduction Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable Late Deductions'),
                value: _lateEnabled,
                onChanged: (val) => setState(() => _lateEnabled = val),
              ),
              if (_lateEnabled) ...[
                const SizedBox(height: 12),
                TextField(controller: _lateDeductionCtrl, decoration: const InputDecoration(labelText: 'Late Deduction Per Minute', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading settings...'),
      error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(payrollSettingsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await AdminOperationsRepository().updatePayrollSettings({
        'payroll_period': _periodCtrl.text,
        'currency': _currencyCtrl.text,
        'overtime_enabled': _otEnabled,
        'overtime_multiplier': double.tryParse(_otMultiplierCtrl.text) ?? 1.5,
        'late_deduction_enabled': _lateEnabled,
        'late_deduction_per_minute': double.tryParse(_lateDeductionCtrl.text) ?? 0,
      });
      ref.invalidate(payrollSettingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Settings saved'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }
}