import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';
import 'package:open_filex/open_filex.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _selectedType;
  String _dateFilter = 'Month'; // Today, Week, Month, Year
  bool _isLoading = false;
  bool _isExporting = false;
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
          _buildDateFilters(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      const Text('Report Generated', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success)),
                    ]),
                    if (_isExporting)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      IconButton(
                        icon: const Icon(Icons.download, color: AppColors.success),
                        onPressed: () => _export(_selectedType!),
                        tooltip: 'Export to Excel',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_result!.entries.map((e) => '${e.key}: ${e.value}').join('\n'), style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    final filters = ['Today', 'Week', 'Month', 'Year'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _dateFilter == f,
            onSelected: (selected) {
              if (selected) setState(() => _dateFilter = f);
            },
            selectedColor: AppColors.primary.withAlpha(50),
            labelStyle: TextStyle(color: _dateFilter == f ? AppColors.primary : AppColors.grey700),
          ),
        )).toList(),
      ),
    );
  }

  Map<String, dynamic> _getDateParams() {
    final now = DateTime.now();
    DateTime from;
    DateTime to = now;

    switch (_dateFilter) {
      case 'Today':
        from = now;
        break;
      case 'Week':
        from = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Year':
        from = DateTime(now.year, 1, 1);
        break;
      case 'Month':
      default:
        from = DateTime(now.year, now.month, 1);
        break;
    }

    return {
      'date_from': from.toString().substring(0, 10),
      'date_to': to.toString().substring(0, 10),
    };
  }

  Future<void> _generate(String type) async {
    setState(() { _selectedType = type; _isLoading = true; _result = null; });
    try {
      final params = _getDateParams();
      final result = await AdminOperationsRepository().generateReport(type: type, params: params);
      setState(() { _result = result; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _export(String type) async {
    setState(() { _isExporting = true; });
    try {
      final params = _getDateParams();
      final path = await AdminOperationsRepository().exportReport(type: type, params: params);
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Report exported successfully!'), backgroundColor: AppColors.success));
      
      // Open the file
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}'), backgroundColor: AppColors.warning));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Export failed: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() { _isExporting = false; });
    }
  }
}