import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.payrollManagementTitle,
          style: const TextStyle(
            color: AppColors.grey800,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showGenerateDialog(context, ref),
            icon: const Icon(Icons.play_arrow),
            label: Text(AppLocalizations.of(context)!.generatePayrollBtn),
          ),
        ),
        Expanded(
          child: runsAsync.when(
            data: (items) => items.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noPayrollRuns, style: const TextStyle(color: AppColors.grey400)))
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
                          if (r.status == 'draft') {
                            _showStatusDialog(context, ref, r);
                          } else {
                            context.push('/company-admin/payroll/${r.period}');
                          }
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
                                    Text(AppLocalizations.of(context)!.employeeCount(r.employeesCount, r.employeesCount == 1 ? '' : 's'), style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
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
            loading: () => LoadingIndicator(message: AppLocalizations.of(context)!.loadingPayrollRuns),
            error: (e, _) => Center(
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(payrollRunsProvider),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.tryAgain),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, PayrollRunData run) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.payrollRunTitle(run.period)),
        content: Text(AppLocalizations.of(context)!.payrollRunPrompt),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/company-admin/payroll/${run.period}');
            },
            child: Text(AppLocalizations.of(context)!.viewPayslipsBtn),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text(AppLocalizations.of(context)!.markCompletedBtn),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminOpsRepositoryProvider).updatePayrollRunStatus(run.id, 'completed');
              ref.invalidate(payrollRunsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.payrollRunMarkedCompleted), backgroundColor: AppColors.success),
                );
              }
            },
          ),
        ],
      ),
    );
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
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.white,
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
                        style: const TextStyle(
                          color: AppColors.grey800,
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

  bool _otEnabled = false;
  bool _lateEnabled = false;
  
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
