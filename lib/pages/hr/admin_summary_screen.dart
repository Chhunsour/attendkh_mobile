import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/summary_repository.dart';

class AdminSummaryScreen extends StatefulWidget {
  const AdminSummaryScreen({super.key});

  @override
  State<AdminSummaryScreen> createState() => _AdminSummaryScreenState();
}

class _AdminSummaryScreenState extends State<AdminSummaryScreen> {
  final _repo = SummaryRepository();
  bool _isLoading = false;
  List<Map<String, dynamic>> _data = [];
  String? _selectedType;
  String _searchQuery = '';

  static const _summaryTypes = [
    {
      'key': 'leave',
      'label': 'Leave Summary',
      'icon': Icons.event_note_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'key': 'overtime',
      'label': 'Overtime Summary',
      'icon': Icons.more_time_rounded,
      'color': Color(0xFFF97316),
    },
    {
      'key': 'payroll',
      'label': 'Payroll Summary',
      'icon': Icons.payments_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'key': 'expense',
      'label': 'Expense Summary',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFFEC4899),
    },
    {
      'key': 'performance',
      'label': 'Performance Summary',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFFA855F7),
    },
    {
      'key': 'recruitment',
      'label': 'Recruitment Summary',
      'icon': Icons.work_outline_rounded,
      'color': Color(0xFF0052FF),
    },
    {
      'key': 'training',
      'label': 'Training Summary',
      'icon': Icons.school_rounded,
      'color': Color(0xFF10B981),
    },
  ];

  Future<void> _loadSummary(String type) async {
    setState(() {
      _isLoading = true;
      _selectedType = type;
      _data = [];
      _searchQuery = '';
    });
    try {
      final result = await _repo.fetchSummary(type: type);
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) return _data;
    final q = _searchQuery.toLowerCase();
    return _data
        .where((r) => r.values.any((v) => v?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<String> get _columns {
    if (_data.isEmpty) return [];
    return _data.first.keys.toList();
  }

  String _fmtValue(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.isEmpty) return '—';
    return s;
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
          'Summary Reports',
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary type grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: _summaryTypes.map((t) {
                final isSelected = _selectedType == t['key'];
                final color = t['color'] as Color;
                return InkWell(
                  onTap: () => _loadSummary(t['key'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(10) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : AppColors.grey200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t['icon'] as IconData, color: color, size: 18),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : AppColors.grey800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? color.withAlpha(180) : AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Loading state
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Data table
            if (!_isLoading && _selectedType != null && _data.isNotEmpty) ...[
              // Search bar
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              // Record count
              Text(
                '${_filteredData.length} records',
                style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Horizontal scrollable table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(AppColors.grey50),
                    columns: _columns
                        .map((c) => DataColumn(
                              label: Text(
                                c.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey700,
                                ),
                              ),
                            ))
                        .toList(),
                    rows: _filteredData
                        .map((row) => DataRow(
                              cells: _columns
                                  .map((c) => DataCell(
                                        Text(
                                          _fmtValue(row[c]),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey700,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],

            // Empty state
            if (!_isLoading && _selectedType != null && _data.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey300),
                      const SizedBox(height: 12),
                      Text(
                        'No data available',
                        style: TextStyle(fontSize: 14, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
              ),

            // Initial state
            if (_selectedType == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.assessment_rounded, size: 48, color: AppColors.grey300),
                      const SizedBox(height: 12),
                      Text(
                        'Select a summary type above',
                        style: TextStyle(fontSize: 14, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
