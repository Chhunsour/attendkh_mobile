import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'dart:math' as math;
import '../../services/admin_operations_repository.dart';

class FormulasScreen extends StatelessWidget {
  final PayrollSettingsData settings;

  const FormulasScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = settings.currencySymbol;
    final fixedDays = settings.fixedWorkingDays > 0 ? settings.fixedWorkingDays : 22;
    final hourlyRate = (1000 / fixedDays) / 8;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.formulasHandbookScreenTitle, style: const TextStyle(color: Colors.black87)),
        backgroundColor: AppColors.surfaceLight,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calculate, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n.formulasHandbookScreenTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.formulasHandbookSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13, height: 1.4),
                  children: [
                    TextSpan(text: l10n.formulasExampleBasis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: l10n.formulasExampleBasisDetail),
                    TextSpan(text: l10n.formulasSalaryExample(symbol), style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: l10n.formulasWorkHours),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: l10n.hourlyRateCalcTitle,
              icon: Icons.calculate_outlined,
              iconColor: Colors.teal,
              description: l10n.hourlyRateCalcDesc,
              formula: settings.workingDaysType == 'fixed'
                  ? l10n.hourlyRateFormulaFixed(fixedDays)
                  : l10n.hourlyRateFormulaActual,
              example: settings.workingDaysType == 'fixed'
                  ? l10n.hourlyRateExampleFixed(symbol, fixedDays, hourlyRate.toStringAsFixed(2))
                  : l10n.hourlyRateExampleActual(symbol, ((1000 / 22) / 8).toStringAsFixed(2)),
            ),
            const SizedBox(height: 16),
            _buildLateDeductionSection(context, l10n, hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildEarlyLeaveSection(context, l10n, hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildOvertimeSection(context, l10n, hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildEarlyClockInSection(context, l10n, hourlyRate, symbol),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String description,
    required String formula,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              formula,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey.shade800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            example,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildLateDeductionSection(BuildContext context, AppLocalizations l10n, double hourlyRate, String symbol) {
    if (!settings.lateDeductionEnabled) {
      return _buildDisabledSection(l10n.lateDeductionFormulaTitle, Icons.shield_outlined, l10n.lateDeductionDisabled);
    }

    String formula = '';
    String example = '';
    final rate = settings.lateDeductionRate;
    final grace = settings.lateGracePeriodMinutes;
    
    if (settings.lateDeductionType == 'per_minute') {
      formula = l10n.lateFormulaPerMinute(grace, rate.toString());
      final lateMins = 30;
      final ded = (lateMins - grace) * (hourlyRate / 60) * rate;
      example = l10n.lateExamplePerMinute(grace, symbol, hourlyRate.toStringAsFixed(2), rate.toString(), ded.toStringAsFixed(2));
    } else if (settings.lateDeductionType == 'fixed_amount') {
      formula = l10n.lateFormulaFixed(symbol, rate.toString());
      example = l10n.lateExampleFixed(grace, symbol, rate.toString());
    } else if (settings.lateDeductionType == 'half_day') {
      formula = l10n.lateFormulaHalfDay;
      final halfDay = (hourlyRate * 8) / 2;
      example = l10n.lateExampleHalfDay(symbol, halfDay.toStringAsFixed(2));
    }

    return _buildSection(
      title: l10n.lateDeductionFormulaTitle,
      icon: Icons.shield_outlined,
      iconColor: Colors.red,
      description: l10n.lateGraceDesc(grace),
      formula: formula,
      example: example,
    );
  }

  Widget _buildEarlyLeaveSection(BuildContext context, AppLocalizations l10n, double hourlyRate, String symbol) {
    if (!settings.lateDeductionEnabled) {
      return _buildDisabledSection(l10n.earlyLeaveFormulaTitle, Icons.shield_outlined, l10n.earlyLeaveDeductionDisabled);
    }

    String formula = '';
    String example = '';
    final rate = settings.earlyLeaveDeductionRate;
    final grace = settings.earlyLeaveGracePeriodMinutes;
    
    if (settings.earlyLeaveDeductionType == 'per_minute') {
      formula = l10n.earlyLeaveFormulaPerMinute(grace, rate.toString());
      final earlyMins = 30;
      final ded = (earlyMins - grace) * (hourlyRate / 60) * rate;
      example = l10n.earlyLeaveExamplePerMinute(grace, symbol, hourlyRate.toStringAsFixed(2), rate.toString(), ded.toStringAsFixed(2));
    } else if (settings.earlyLeaveDeductionType == 'fixed_amount') {
      formula = l10n.earlyLeaveFormulaFixed(symbol, rate.toString());
      example = l10n.earlyLeaveExampleFixed(grace, symbol, rate.toString());
    } else if (settings.earlyLeaveDeductionType == 'half_day') {
      formula = l10n.earlyLeaveFormulaHalfDay;
      final halfDay = (hourlyRate * 8) / 2;
      example = l10n.earlyLeaveExampleHalfDay(symbol, halfDay.toStringAsFixed(2));
    }

    return _buildSection(
      title: l10n.earlyLeaveFormulaTitle,
      icon: Icons.shield_outlined,
      iconColor: Colors.red,
      description: l10n.earlyLeaveGraceDesc(grace),
      formula: formula,
      example: example,
    );
  }

  Widget _buildOvertimeSection(BuildContext context, AppLocalizations l10n, double hourlyRate, String symbol) {
    if (!settings.overtimeEnabled) {
      return _buildDisabledSection(l10n.overtimeCalcTitle, Icons.menu_book, l10n.overtimeDisabled);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(l10n.overtimeCalcTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.overtimeCalcDesc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          _buildOtBox(
            title: l10n.otRegularWorkDay,
            formula: l10n.otFormulaRegular(settings.regularOtMultiplier.toString()),
            example: l10n.otExampleRegular(symbol, hourlyRate.toStringAsFixed(2), settings.regularOtMultiplier.toString(), (2 * hourlyRate * settings.regularOtMultiplier).toStringAsFixed(2)),
            hourlyRate: hourlyRate,
            symbol: symbol,
          ),
          const SizedBox(height: 8),
          _buildOtBox(
            title: l10n.otRestDay,
            formula: l10n.otFormulaRegular(settings.restDayOtMultiplier.toString()),
            example: l10n.otExampleFullDay(symbol, hourlyRate.toStringAsFixed(2), settings.restDayOtMultiplier.toString(), (8 * hourlyRate * settings.restDayOtMultiplier).toStringAsFixed(2)),
            hourlyRate: hourlyRate,
            symbol: symbol,
          ),
          const SizedBox(height: 8),
          _buildOtBox(
            title: l10n.otHoliday,
            formula: l10n.otFormulaRegular(math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier).toString()),
            example: l10n.otExampleFullDay(symbol, hourlyRate.toStringAsFixed(2), math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier).toString(), (8 * hourlyRate * math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier)).toStringAsFixed(2)),
            hourlyRate: hourlyRate,
            symbol: symbol,
          ),
        ],
      ),
    );
  }

  Widget _buildOtBox({required String title, required String formula, required String example, required double hourlyRate, required String symbol}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade400, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(formula, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.indigo.shade900)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12, height: 1),
          ),
          Text(example, style: TextStyle(color: Colors.indigo.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildEarlyClockInSection(BuildContext context, AppLocalizations l10n, double hourlyRate, String symbol) {
    String formula = '';
    String example = '';
    
    if (settings.earlyClockInPolicy == 'ignore') {
      formula = l10n.earlyClockInIgnoreFormula;
    } else if (settings.earlyClockInPolicy == 'treat_as_ot') {
      formula = l10n.earlyClockInOtFormula(settings.maxPreShiftOtMinutes, settings.preShiftOtMultiplier.toString());
      example = l10n.earlyClockInOtExample(symbol, hourlyRate.toStringAsFixed(2), settings.preShiftOtMultiplier.toString(), (1 * hourlyRate * settings.preShiftOtMultiplier).toStringAsFixed(2));
    } else if (settings.earlyClockInPolicy == 'paid_outside') {
      formula = l10n.earlyClockInPaidOutsideFormula;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(l10n.earlyClockInPolicyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formula, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange.shade900)),
                if (example.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.black12, height: 1),
                  ),
                  Text(example, style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledSection(String title, IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
