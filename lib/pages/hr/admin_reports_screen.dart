import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final reportTypes = [
      {'key': 'employees', 'label': l10n.reportEmployees, 'icon': Icons.people, 'color': AppColors.secondary},
      {'key': 'attendance', 'label': l10n.reportAttendance, 'icon': Icons.access_time, 'color': AppColors.success},
      {'key': 'leave', 'label': l10n.reportLeave, 'icon': Icons.event_note, 'color': AppColors.warning},
      {'key': 'payroll', 'label': l10n.reportPayroll, 'icon': Icons.receipt_long, 'color': AppColors.info},
      {'key': 'expenses', 'label': l10n.reportExpenses, 'icon': Icons.receipt, 'color': AppColors.danger},
      {'key': 'assets', 'label': l10n.reportAssets, 'icon': Icons.inventory_2, 'color': AppColors.primary},
      {'key': 'recruitment', 'label': l10n.reportRecruitment, 'icon': Icons.work, 'color': AppColors.secondaryDark},
      {'key': 'performance', 'label': l10n.reportPerformance, 'icon': Icons.assessment, 'color': AppColors.primaryDark},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.reportsTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.generateReportTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800)),
            const SizedBox(height: 8),
            Text(l10n.selectReportTypeHint, style: TextStyle(fontSize: 13, color: AppColors.grey500)),
            const SizedBox(height: 16),
            _buildDateFilters(l10n),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4),
                itemCount: reportTypes.length,
                itemBuilder: (context, i) {
                  final r = reportTypes[i];
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
              LoadingIndicator(message: l10n.generatingReport),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters(AppLocalizations l10n) {
    final filters = [
      l10n.filterToday,
      l10n.filterWeek,
      l10n.filterMonth,
      l10n.filterYear,
    ];
    final filterKeys = ['Today', 'Week', 'Month', 'Year'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (idx) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(filters[idx]),
            selected: _dateFilter == filterKeys[idx],
            onSelected: (selected) {
              if (selected) setState(() => _dateFilter = filterKeys[idx]);
            },
            selectedColor: AppColors.primary.withAlpha(50),
            labelStyle: TextStyle(color: _dateFilter == filterKeys[idx] ? AppColors.primary : AppColors.grey700),
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
    setState(() { _selectedType = type; _isLoading = true; });
    try {
      final params = _getDateParams();
      final result = await AdminOperationsRepository().generateReport(type: type, params: params);
      setState(() { _isLoading = false; });
      if (mounted) _showResultsSheet(result, type);
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
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.reportExportSuccess), backgroundColor: AppColors.success));
      
      // Open the file
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenFile(result.message)), backgroundColor: AppColors.warning));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.reportExportFailed(e.toString())), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() { _isExporting = false; });
    }
  }

  void _showResultsSheet(Map<String, dynamic> data, String type) {
    final l10n = AppLocalizations.of(context)!;
    final records = data['records'] as List<dynamic>? ?? [];
    final total = data['total'] ?? 0;
    
    final rType = _reportTypes.firstWhere((e) => e['key'] == type);
    final color = rType['color'] as Color;
    final label = rType['label'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                            child: Icon(rType['icon'] as IconData, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.reportLabelSuffix(label), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                              Text(l10n.reportFoundRecords(total), style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_isExporting)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.download, color: AppColors.primary),
                              onPressed: () async {
                                setSheetState(() => _isExporting = true);
                                await _export(type);
                                if (ctx.mounted) setSheetState(() => _isExporting = false);
                              },
                              tooltip: l10n.exportReportTooltip,
                            ),
                          IconButton(icon: const Icon(Icons.close, color: AppColors.grey500), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.grey200),
                Expanded(
                  child: records.isEmpty
                      ? Center(child: Text(l10n.noRecordsFound, style: const TextStyle(color: AppColors.grey500)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final record = records[i] as Map<String, dynamic>;
                            return _buildRecordCard(record, color);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, Color themeColor) {
    // Try to extract a title from common fields
    String title = record['full_name'] ?? record['candidate_name'] ?? record['asset_name'] ?? record['title'] ?? 'Record';
    String? subtitle = record['emp_code'] ?? record['asset_code'] ?? record['period'] ?? record['job_title'] ?? record['category'];
    String? status = record['status'] ?? record['stage'];

    // Remove these from the generic list so we don't duplicate them
    final displayData = Map<String, dynamic>.from(record)
      ..removeWhere((k, v) => ['full_name', 'candidate_name', 'asset_name', 'title', 'emp_code', 'asset_code', 'period', 'job_title', 'category', 'status', 'stage'].contains(k));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: AppColors.grey200.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                      ]
                    ],
                  ),
                ),
                if (status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: themeColor.withAlpha(26), borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: themeColor)),
                  ),
              ],
            ),
          ),
          if (displayData.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.grey50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: displayData.entries.map((e) {
                  final key = e.key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
                  final val = e.value?.toString() ?? '-';
                  return SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(key, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(val, style: const TextStyle(fontSize: 13, color: AppColors.grey800, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }

}