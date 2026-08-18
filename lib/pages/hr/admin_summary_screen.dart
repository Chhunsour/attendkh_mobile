import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  Map<String, dynamic> _fullResponse = {};
  String? _selectedType;
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime.now();

  static const _summaryTypes = [
    {
      'key': 'leave',
      'label': 'Leave Summary',
      'icon': Icons.event_note_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'key': 'attendance',
      'label': 'Attendance Summary',
      'icon': Icons.fingerprint_rounded,
      'color': Color(0xFF10B981),
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
      _fullResponse = {};
      _searchQuery = '';
    });
    try {
      final filters = <String, dynamic>{};
      if (type == 'attendance') {
        filters['month'] = DateFormat('yyyy-MM').format(_selectedMonth);
      }

      if (type == 'attendance') {
        final result = await _repo.fetchSpecializedSummary(
          type: type,
          filters: filters,
        );
        if (mounted) {
          setState(() {
            _fullResponse = result;
            _data =
                (result['data'] as List<dynamic>?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                [];
            _isLoading = false;
          });
        }
      } else {
        final result = await _repo.fetchSummary(type: type, filters: filters);
        if (mounted) {
          setState(() {
            _data = result;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) return _data;
    final q = _searchQuery.toLowerCase();
    return _data
        .where(
          (r) => r.values.any(
            (v) => v?.toString().toLowerCase().contains(q) ?? false,
          ),
        )
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

  void _changeMonth(int offset) {
    if (_selectedType == null) return;
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
    _loadSummary(_selectedType!);
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.transparent;
    switch (status) {
      case 'present':
        return const Color(0xFF10B981);
      case 'absent':
        return const Color(0xFFEF4444);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'half_day':
        return const Color(0xFF3B82F6);
      case 'on_leave':
        return const Color(0xFF8B5CF6);
      case 'holiday':
        return const Color(0xFFEC4899);
      case 'weekend':
        return AppColors.grey200;
      default:
        return AppColors.grey100;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return '';
    switch (status) {
      case 'present':
        return 'P';
      case 'absent':
        return 'A';
      case 'late':
        return 'L';
      case 'half_day':
        return 'H';
      case 'on_leave':
        return 'V';
      case 'holiday':
        return 'H';
      case 'weekend':
        return 'W';
      default:
        return '-';
    }
  }

  Widget _buildLegendItem(String label, String full, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            full,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMatrixTable() {
    final daysInMonth =
        _fullResponse['daysInMonth'] as int? ??
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    return DataTable(
      columnSpacing: 8,
      horizontalMargin: 12,
      headingRowHeight: 40,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 56,
      headingRowColor: WidgetStateProperty.all(AppColors.grey50),
      columns: [
        const DataColumn(
          label: Text(
            'Employee',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        ...List.generate(
          daysInMonth,
          (index) => DataColumn(
            label: Container(
              width: 20,
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const DataColumn(
          label: Text(
            'P',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const DataColumn(
          label: Text(
            'A',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
        const DataColumn(
          label: Text(
            'L',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
      rows: _filteredData.map((row) {
        final emp = row['employee'] as Map<String, dynamic>? ?? {};
        final days = (row['days'] as Map<String, dynamic>?) ?? {};
        final totals = (row['totals'] as Map<String, dynamic>?) ?? {};
        final photoUrl = emp['photo_url']?.toString();

        return DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.grey100,
                      border: Border.all(color: AppColors.grey200, width: 0.5),
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const Icon(
                                Icons.person,
                                size: 14,
                                color: AppColors.grey400,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.grey400,
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      Text(
                        emp['employee_id'] ?? '-',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ...List.generate(daysInMonth, (index) {
              final dayStr = (index + 1).toString();
              final status = days[dayStr];
              return DataCell(
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getStatusLabel(status),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            DataCell(
              Text(
                '${totals['present'] ?? 0}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            DataCell(
              Text(
                '${totals['absent'] ?? 0}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            DataCell(
              Text(
                '${totals['late'] ?? 0}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
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
                          child: Icon(
                            t['icon'] as IconData,
                            color: color,
                            size: 18,
                          ),
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
                                color: isSelected
                                    ? color.withAlpha(180)
                                    : AppColors.grey500,
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

            // Month Picker for Attendance
            if (_selectedType == 'attendance') ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.grey600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.grey600,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Legend
              Container(
                height: 32,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildLegendItem('P', 'Present', const Color(0xFF10B981)),
                    _buildLegendItem('A', 'Absent', const Color(0xFFEF4444)),
                    _buildLegendItem('L', 'Late', const Color(0xFFF59E0B)),
                    _buildLegendItem('V', 'Leave', const Color(0xFF8B5CF6)),
                    _buildLegendItem('W', 'Weekend', AppColors.grey300),
                  ],
                ),
              ),
            ],

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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Record count
              Text(
                '${_filteredData.length} records',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w600,
                ),
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
                  child: _selectedType == 'attendance'
                      ? _buildAttendanceMatrixTable()
                      : DataTable(
                          columnSpacing: 16,
                          horizontalMargin: 12,
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.grey50,
                          ),
                          columns: _columns
                              .map(
                                (c) => DataColumn(
                                  label: Text(
                                    c
                                        .replaceAll('_', ' ')
                                        .split(' ')
                                        .map(
                                          (w) => w.isNotEmpty
                                              ? '${w[0].toUpperCase()}${w.substring(1)}'
                                              : '',
                                        )
                                        .join(' '),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          rows: _filteredData
                              .map(
                                (row) => DataRow(
                                  cells: _columns
                                      .map(
                                        (c) => DataCell(
                                          Text(
                                            _fmtValue(row[c]),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey700,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
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
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No data available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey500,
                        ),
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
                      Icon(
                        Icons.assessment_rounded,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select a summary type above',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey500,
                        ),
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
