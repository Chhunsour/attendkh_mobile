import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _selectedType;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  static const _reportTypes = [
    {'key': 'employees', 'label': 'Employees', 'icon': Icons.people, 'color': AppColors.secondary},
    {'key': 'attendance', 'label': 'Attendance', 'icon': Icons.access_time, 'color': AppColors.success},
    {'key': 'leave', 'label': 'Leave', 'icon': Icons.event_note, 'color': AppColors.warning},
    {'key': 'payroll', 'label': 'Payroll', 'icon': Icons.receipt_long, 'color': AppColors.info},
    {'key': 'expenses', 'label': 'Expenses', 'icon': Icons.receipt, 'color': AppColors.danger},
    {'key': 'assets', 'label': 'Assets', 'icon': Icons.inventory_2, 'color': AppColors.primary},
    {'key': 'recruitment', 'label': 'Recruitment', 'icon': Icons.work, 'color': AppColors.secondaryDark},
    {'key': 'performance', 'label': 'Performance', 'icon': Icons.assessment, 'color': AppColors.primaryDark},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generate Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800)),
          const SizedBox(height: 8),
          Text('Select a report type to generate', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4),
              itemCount: _reportTypes.length,
              itemBuilder: (context, i) {
                final r = _reportTypes[i];
                final isSelected = _selectedType == r['key'];
                return GestureDetector(
                  onTap: () => _generate(r['key'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? (r['color'] as Color).withAlpha(26) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? r['color'] as Color : AppColors.grey200, width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 28),
                        const SizedBox(height: 8),
                        Text(r['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? r['color'] as Color : AppColors.grey700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const LoadingIndicator(message: 'Generating report...'),
          ],
          if (_result != null && !_isLoading) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withAlpha(76))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text('Report Generated', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                ]),
                const SizedBox(height: 8),
                Text(_result!.entries.map((e) => '${e.key}: ${e.value}').join('\n'), style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate(String type) async {
    setState(() { _selectedType = type; _isLoading = true; _result = null; });
    try {
      final result = await AdminOperationsRepository().generateReport(type: type);
      setState(() { _result = result; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }
}