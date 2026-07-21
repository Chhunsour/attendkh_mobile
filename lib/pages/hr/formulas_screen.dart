import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'dart:math' as math;
import '../../services/admin_operations_repository.dart';

class FormulasScreen extends StatelessWidget {
  final PayrollSettingsData settings;

  const FormulasScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final symbol = settings.currencySymbol;
    final fixedDays = settings.fixedWorkingDays > 0 ? settings.fixedWorkingDays : 22;
    final hourlyRate = (1000 / fixedDays) / 8;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Payroll Formulas Handbook', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calculate, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Payroll Formulas Handbook',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Verify how your current rules translate into mathematical formulas for payroll calculation.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                    const TextSpan(text: 'Real-World Example Basis: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'For the examples below, we assume an employee earns a base salary of '),
                    TextSpan(text: '${symbol}1,000/month', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' and works 8 hours per day.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Hourly Rate Calculation',
              icon: Icons.calculate_outlined,
              iconColor: Colors.teal,
              description: 'The hourly rate is the foundation for all overtime and deduction calculations.',
              formula: settings.workingDaysType == 'fixed'
                  ? 'Hourly Rate = (Monthly Salary / $fixedDays fixed days) / 8 hours'
                  : 'Hourly Rate = (Monthly Salary / Actual working days in month) / 8 hours',
              example: settings.workingDaysType == 'fixed'
                  ? 'Example: (${symbol}1,000 ÷ $fixedDays days) ÷ 8 hrs = $symbol${hourlyRate.toStringAsFixed(2)} per hour.'
                  : 'Example: (${symbol}1,000 ÷ 22 days) ÷ 8 hrs = $symbol${((1000 / 22) / 8).toStringAsFixed(2)} per hour.',
            ),
            const SizedBox(height: 16),
            _buildLateDeductionSection(hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildEarlyLeaveSection(hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildOvertimeSection(hourlyRate, symbol),
            const SizedBox(height: 16),
            _buildEarlyClockInSection(hourlyRate, symbol),
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

  Widget _buildLateDeductionSection(double hourlyRate, String symbol) {
    if (!settings.lateDeductionEnabled) {
      return _buildDisabledSection('Late Deduction Formula', Icons.shield_outlined, 'Late deductions are currently disabled.');
    }

    String formula = '';
    String example = '';
    final rate = settings.lateDeductionRate;
    final grace = settings.lateGracePeriodMinutes;
    
    if (settings.lateDeductionType == 'per_minute') {
      formula = 'Total Deduction = (Late Minutes - $grace) * (Hourly Rate / 60) * $rate (multiplier)';
      final lateMins = 30;
      final ded = (lateMins - grace) * (hourlyRate / 60) * rate;
      example = 'Example (30 mins late): (30 - ${grace}m grace) * ($symbol${hourlyRate.toStringAsFixed(2)}/60) * ${rate}x = $symbol${ded.toStringAsFixed(2)} deducted.';
    } else if (settings.lateDeductionType == 'fixed_amount') {
      formula = 'Total Deduction = $symbol$rate (Fixed flat fee)';
      example = 'Example: Employee is 20 minutes late (past the ${grace}m grace). They are deducted exactly $symbol$rate.';
    } else if (settings.lateDeductionType == 'half_day') {
      formula = 'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)';
      final halfDay = (hourlyRate * 8) / 2;
      example = 'Example: Employee is 20 minutes late (past grace). Half day salary ($symbol${halfDay.toStringAsFixed(2)}) is deducted.';
    }

    return _buildSection(
      title: 'Late Deduction Formula',
      icon: Icons.shield_outlined,
      iconColor: Colors.red,
      description: 'Employees have a grace period of $grace minutes. If an employee is late beyond the grace period, the deduction is calculated as follows:',
      formula: formula,
      example: example,
    );
  }

  Widget _buildEarlyLeaveSection(double hourlyRate, String symbol) {
    if (!settings.lateDeductionEnabled) {
      return _buildDisabledSection('Early Leave Deduction Formula', Icons.shield_outlined, 'Early leave deductions are currently disabled.');
    }

    String formula = '';
    String example = '';
    final rate = settings.earlyLeaveDeductionRate;
    final grace = settings.earlyLeaveGracePeriodMinutes;
    
    if (settings.earlyLeaveDeductionType == 'per_minute') {
      formula = 'Total Deduction = (Early Leave Minutes - $grace) * (Hourly Rate / 60) * $rate (multiplier)';
      final earlyMins = 30;
      final ded = (earlyMins - grace) * (hourlyRate / 60) * rate;
      example = 'Example (30 mins early): (30 - ${grace}m grace) * ($symbol${hourlyRate.toStringAsFixed(2)}/60) * ${rate}x = $symbol${ded.toStringAsFixed(2)} deducted.';
    } else if (settings.earlyLeaveDeductionType == 'fixed_amount') {
      formula = 'Total Deduction = $symbol$rate (Fixed flat fee)';
      example = 'Example: Employee leaves 20 minutes early (past the ${grace}m grace). They are deducted exactly $symbol$rate.';
    } else if (settings.earlyLeaveDeductionType == 'half_day') {
      formula = 'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)';
      final halfDay = (hourlyRate * 8) / 2;
      example = 'Example: Employee leaves 20 minutes early (past grace). Half day salary ($symbol${halfDay.toStringAsFixed(2)}) is deducted.';
    }

    return _buildSection(
      title: 'Early Leave Deduction Formula',
      icon: Icons.shield_outlined,
      iconColor: Colors.red,
      description: 'Employees have a grace period of $grace minutes. If an employee leaves early beyond the grace period, the deduction is calculated as follows:',
      formula: formula,
      example: example,
    );
  }

  Widget _buildOvertimeSection(double hourlyRate, String symbol) {
    if (!settings.overtimeEnabled) {
      return _buildDisabledSection('Overtime Calculation', Icons.menu_book, 'Overtime is currently disabled.');
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
          const Row(
            children: [
              Icon(Icons.menu_book, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text('Overtime Calculation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Overtime payout is calculated by multiplying the active Hourly Rate by the OT hours worked and the respective day\'s multiplier.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          _buildOtBox(
            title: 'Regular Work Day',
            formula: 'OT Payout = OT Hours * Hourly Rate * ${settings.regularOtMultiplier}',
            example: 'Example (2 hours OT): 2 hrs * \$${hourlyRate.toStringAsFixed(2)} * ${settings.regularOtMultiplier}x = $symbol${(2 * hourlyRate * settings.regularOtMultiplier).toStringAsFixed(2)} total pay.',
            hourlyRate: hourlyRate,
            symbol: symbol,
          ),
          const SizedBox(height: 8),
          _buildOtBox(
            title: 'Rest Day (Day Off)',
            formula: 'OT Payout = OT Hours * Hourly Rate * ${settings.restDayOtMultiplier}',
            example: 'Example (8 hours worked): 8 hrs * \$${hourlyRate.toStringAsFixed(2)} * ${settings.restDayOtMultiplier}x = $symbol${(8 * hourlyRate * settings.restDayOtMultiplier).toStringAsFixed(2)} total pay.',
            hourlyRate: hourlyRate,
            symbol: symbol,
          ),
          const SizedBox(height: 8),
          _buildOtBox(
            title: 'Company / Public Holiday',
            formula: 'OT Payout = OT Hours * Hourly Rate * ${math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier)}',
            example: 'Example (8 hours worked): 8 hrs * \$${hourlyRate.toStringAsFixed(2)} * ${math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier)}x = $symbol${(8 * hourlyRate * math.max(settings.companyHolidayOtMultiplier, settings.publicHolidayOtMultiplier)).toStringAsFixed(2)} total pay.',
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

  Widget _buildEarlyClockInSection(double hourlyRate, String symbol) {
    String formula = '';
    String example = '';
    
    if (settings.earlyClockInPolicy == 'ignore') {
      formula = 'Early clock-ins do NOT generate extra pay (Ignored in payroll).';
    } else if (settings.earlyClockInPolicy == 'treat_as_ot') {
      formula = 'Early clock-ins are treated as OT.\nPayout = Early OT Hours (Max ${settings.maxPreShiftOtMinutes} mins) * Hourly Rate * ${settings.preShiftOtMultiplier}';
      example = 'Example (1 hr early): 1 hr * \$${hourlyRate.toStringAsFixed(2)} * ${settings.preShiftOtMultiplier}x = $symbol${(1 * hourlyRate * settings.preShiftOtMultiplier).toStringAsFixed(2)} total pay.';
    } else if (settings.earlyClockInPolicy == 'paid_outside') {
      formula = 'Early clock-ins are paid manually outside of standard payroll.';
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
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Early Clock-in Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
