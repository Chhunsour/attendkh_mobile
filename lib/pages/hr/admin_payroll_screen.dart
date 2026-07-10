import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Payroll Management',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
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
                      final statusColor = r.status == 'completed'
                          ? AppColors.success
                          : r.status == 'processing'
                              ? AppColors.info
                              : AppColors.warning;
                      return GestureDetector(
                        onTap: () {
                          context.push('/company-admin/payroll/${r.period}');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.receipt_long, color: statusColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.period, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    Text('${r.employeesCount} employees', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${r.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      r.status.substring(0, 1).toUpperCase() + r.status.substring(1),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppColors.grey400),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingIndicator(message: 'Loading payroll runs...'),
            error: (e, _) => Center(
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(payrollRunsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGenerateDialog(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final periodStartCtrl = TextEditingController(
      text: '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}',
    );
    final periodEndCtrl = TextEditingController(
      text: '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}',
    );

    Future<void> pickDate(TextEditingController ctrl) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(ctrl.text) ?? now,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Payroll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: periodStartCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Period Start', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () => pickDate(periodStartCtrl),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: periodEndCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Period End', suffixIcon: Icon(Icons.calendar_today)),
              onTap: () => pickDate(periodEndCtrl),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await AdminOperationsRepository().generatePayroll(
                  periodStart: periodStartCtrl.text,
                  periodEnd: periodEndCtrl.text,
                );
                ref.invalidate(payrollRunsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Payroll generated'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
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
  final _workingDaysCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController();
  final _otThresholdCtrl = TextEditingController();
  final _weekendOtCtrl = TextEditingController();
  final _holidayOtCtrl = TextEditingController();
  final _maxOtDayCtrl = TextEditingController();
  final _maxOtWeekCtrl = TextEditingController();
  final _lateDeductionCtrl = TextEditingController();
  final _graceMinutesCtrl = TextEditingController();
  final _lateAmountCtrl = TextEditingController();
  final _halfDayHoursCtrl = TextEditingController();
  final _halfDayPctCtrl = TextEditingController();
  bool _otEnabled = false;
  bool _lateEnabled = false;
  String _lateCalcMethod = 'flat';
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(payrollSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (!_initialized) {
          _periodCtrl.text = settings.payrollPeriod;
          _currencyCtrl.text = settings.currency;
          _currencySymbolCtrl.text = settings.currencySymbol;
          _startDayCtrl.text = settings.payrollStartDay.toString();
          _workingDaysCtrl.text = settings.payrollWorkingDays.toString();
          _otMultiplierCtrl.text = settings.overtimeMultiplier.toString();
          _otThresholdCtrl.text = settings.overtimeThreshold.toString();
          _weekendOtCtrl.text = settings.weekendOvertimeMultiplier.toString();
          _holidayOtCtrl.text = settings.holidayOvertimeMultiplier.toString();
          _maxOtDayCtrl.text = settings.maxOvertimeHoursPerDay.toString();
          _maxOtWeekCtrl.text = settings.maxOvertimeHoursPerWeek.toString();
          _lateDeductionCtrl.text = settings.lateDeductionPerMinute.toString();
          _graceMinutesCtrl.text = settings.gracePeriodMinutes.toString();
          _lateAmountCtrl.text = settings.lateDeductionAmount.toString();
          _halfDayHoursCtrl.text = settings.halfDayHours.toString();
          _halfDayPctCtrl.text = settings.halfDayDeductionPercentage.toString();
          _otEnabled = settings.overtimeEnabled;
          _lateEnabled = settings.lateDeductionEnabled;
          _lateCalcMethod = settings.lateDeductionCalculation;
          _initialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('General Settings'),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Payroll Period',
                value: _periodCtrl.text,
                items: const ['weekly', 'bi_weekly', 'monthly'],
                onChanged: (v) => setState(() => _periodCtrl.text = v),
              ),
              const SizedBox(height: 12),
              _textField(_startDayCtrl, 'Payroll Start Day', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _textField(_workingDaysCtrl, 'Working Days per Period', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _textField(_currencyCtrl, 'Currency (e.g. USD)'),
              const SizedBox(height: 12),
              _textField(_currencySymbolCtrl, 'Currency Symbol (e.g. \$)'),

              const SizedBox(height: 28),
              _sectionHeader('Overtime Settings'),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Overtime Pay'),
                value: _otEnabled,
                onChanged: (val) => setState(() => _otEnabled = val),
              ),
              if (_otEnabled) ...[
                const SizedBox(height: 8),
                _textField(_otThresholdCtrl, 'Overtime Threshold (hours)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_otMultiplierCtrl, 'Overtime Multiplier (e.g. 1.5)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_weekendOtCtrl, 'Weekend Multiplier (e.g. 2.0)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_holidayOtCtrl, 'Holiday Multiplier (e.g. 3.0)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField(_maxOtDayCtrl, 'Max OT Hours / Day', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _textField(_maxOtWeekCtrl, 'Max OT Hours / Week', keyboardType: TextInputType.number),
              ],

              const SizedBox(height: 28),
              _sectionHeader('Late Deduction Settings'),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Late Deductions'),
                value: _lateEnabled,
                onChanged: (val) => setState(() => _lateEnabled = val),
              ),
              if (_lateEnabled) ...[
                const SizedBox(height: 8),
                _textField(_graceMinutesCtrl, 'Grace Period (minutes)', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Calculation Method',
                  value: _lateCalcMethod,
                  items: const ['flat', 'hourly', 'per_minute'],
                  onChanged: (v) => setState(() => _lateCalcMethod = v),
                ),
                const SizedBox(height: 12),
                if (_lateCalcMethod == 'flat')
                  _textField(_lateAmountCtrl, 'Flat Deduction Amount', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                if (_lateCalcMethod != 'flat')
                  _textField(_lateDeductionCtrl, 'Rate per Minute', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],

              const SizedBox(height: 28),
              _sectionHeader('Half-Day Settings'),
              const SizedBox(height: 12),
              _textField(_halfDayHoursCtrl, 'Half-Day Hours', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _textField(_halfDayPctCtrl, 'Half-Day Deduction %', keyboardType: const TextInputType.numberWithOptions(decimal: true)),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(message: 'Loading settings...'),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(payrollSettingsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await AdminOperationsRepository().updatePayrollSettings({
        'payroll_period': _periodCtrl.text,
        'payroll_start_day': int.tryParse(_startDayCtrl.text) ?? 1,
        'payroll_working_days': int.tryParse(_workingDaysCtrl.text) ?? 22,
        'currency': _currencyCtrl.text,
        'currency_symbol': _currencySymbolCtrl.text,
        'overtime_enabled': _otEnabled,
        'overtime_threshold': double.tryParse(_otThresholdCtrl.text) ?? 1.0,
        'overtime_multiplier': double.tryParse(_otMultiplierCtrl.text) ?? 1.5,
        'weekend_overtime_multiplier': double.tryParse(_weekendOtCtrl.text) ?? 2.0,
        'holiday_overtime_multiplier': double.tryParse(_holidayOtCtrl.text) ?? 3.0,
        'max_overtime_hours_per_day': int.tryParse(_maxOtDayCtrl.text) ?? 4,
        'max_overtime_hours_per_week': int.tryParse(_maxOtWeekCtrl.text) ?? 20,
        'late_deduction_enabled': _lateEnabled,
        'grace_period_minutes': int.tryParse(_graceMinutesCtrl.text) ?? 15,
        'late_deduction_calculation': _lateCalcMethod,
        'late_deduction_per_minute': double.tryParse(_lateDeductionCtrl.text) ?? 0,
        'late_deduction_amount': double.tryParse(_lateAmountCtrl.text) ?? 0,
        'half_day_hours': double.tryParse(_halfDayHoursCtrl.text) ?? 4.0,
        'half_day_deduction_percentage': double.tryParse(_halfDayPctCtrl.text) ?? 50.0,
      });
      ref.invalidate(payrollSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Settings saved'), backgroundColor: AppColors.success),
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
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800));
  }

  Widget _textField(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: keyboardType,
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(_formatLabel(i)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'weekly': return 'Weekly';
      case 'bi_weekly': return 'Bi-Weekly';
      case 'monthly': return 'Monthly';
      case 'flat': return 'Flat Amount';
      case 'hourly': return 'Hourly Rate';
      case 'per_minute': return 'Per Minute Rate';
      default: return key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }
}