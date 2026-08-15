import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import '../../services/admin_operations_repository.dart';
import '../../providers/admin_providers.dart';
import '../../components/loading_indicator.dart';
import '../../l10n/app_localizations.dart';
import 'formulas_screen.dart';

class BranchPayrollSettingsScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;

  const BranchPayrollSettingsScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<BranchPayrollSettingsScreen> createState() => _BranchPayrollSettingsScreenState();
}

class _BranchPayrollSettingsScreenState extends ConsumerState<BranchPayrollSettingsScreen> {
  final _periodCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  final _currencySymbolCtrl = TextEditingController();
  final _startDayCtrl = TextEditingController();
  final _workingDaysCtrl = TextEditingController();
  
  final _otThresholdCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController();
  final _weekendOtCtrl = TextEditingController();
  final _pubHolidayOtCtrl = TextEditingController();
  final _compHolidayOtCtrl = TextEditingController();
  
  final _graceMinutesCtrl = TextEditingController();
  final _lateDeductionCtrl = TextEditingController();
  
  final _earlyLeaveGraceCtrl = TextEditingController();
  final _earlyLeaveRateCtrl = TextEditingController();

  final _preShiftOtCtrl = TextEditingController();
  final _maxPreShiftCtrl = TextEditingController();

  final _halfDayHoursCtrl = TextEditingController();
  final _halfDayPctCtrl = TextEditingController();

  final _taxRateCtrl = TextEditingController();
  final _insuranceRateCtrl = TextEditingController();

  bool _isCustom = false;
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
    final settingsAsync = ref.watch(branchPayrollSettingsProvider(widget.branchId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.branchPayrollTitle(widget.branchName), style: const TextStyle(color: AppColors.grey800)),
        backgroundColor: AppColors.surfaceLight,
        iconTheme: const IconThemeData(color: AppColors.grey800),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, color: AppColors.primary),
            tooltip: l10n.formulasHandbookTitle,
            onPressed: () async {
              final s = await ref.read(branchFormulasProvider(widget.branchId).future);
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.push(context, MaterialPageRoute(builder: (_) => FormulasScreen(settings: s)));
              }
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!_initialized) {
            _isCustom = settings.isCustom;
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.branchCustomizationTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.branchCustomizationDesc,
                        style: const TextStyle(color: AppColors.grey500, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.useCustomBranchRulesLabel),
                        value: _isCustom,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _isCustom = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isCustom)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance, size: 64, color: AppColors.grey300),
                          const SizedBox(height: 16),
                          Text(
                            l10n.inheritingCompanyRulesTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.inheritingCompanyRulesDesc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.grey500),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save),
                            label: Text(l10n.saveSettingsBtn),
                          )
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          items: const ['flat', 'hourly', 'per_minute', 'half_day'],
                          onChanged: (v) => setState(() => _lateCalcMethod = v),
                        ),
                        const SizedBox(height: 12),
                        _textField(_lateDeductionCtrl, l10n.deductionRateAmountLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
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
                        items: const ['flat', 'hourly', 'per_minute', 'half_day'],
                        onChanged: (v) => setState(() => _earlyLeaveDedType = v),
                      ),
                      const SizedBox(height: 12),
                      _textField(_earlyLeaveRateCtrl, l10n.deductionRateAmountLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),

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
                      const SizedBox(height: 12),
                      _textField(_preShiftOtCtrl, l10n.preShiftOtMultiplierLabel, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 12),
                      _textField(_maxPreShiftCtrl, l10n.maxAllowedEarlyMinutesLabel, keyboardType: TextInputType.number),

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
                        title: const Text('Enable Tax on Salary (TOAS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Deduct income tax percentage from gross salary', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
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
                        title: const Text('Enable NSSF / Insurance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Deduct social security percentage from base salary', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
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
                        child: Text(l10n.saveBranchSettingsBtn, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => LoadingIndicator(message: AppLocalizations.of(context)!.loadingSettings),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(branchPayrollSettingsProvider(widget.branchId)),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await AdminOperationsRepository().updateBranchPayrollSettings(widget.branchId, {
        'is_custom': _isCustom,
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
      ref.invalidate(branchPayrollSettingsProvider(widget.branchId));
      ref.invalidate(branchFormulasProvider(widget.branchId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.branchSettingsSaved), backgroundColor: AppColors.success),
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
