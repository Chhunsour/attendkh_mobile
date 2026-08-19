import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedType = 'attendance';
  String _dateFilter = 'Month';
  bool _isLoading = false;
  bool _isExporting = false;
  bool _filtersExpanded = true;
  bool _generated = false;

  // Filter values
  String _dateFrom = '';
  String _dateTo = '';
  String _branchId = '';
  String _departmentId = '';
  String _employeeId = '';
  String _statusFilter = '';

  // Filter data
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _employees = [];

  // Results
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _columns = [];
  List<Map<String, dynamic>> _summary = [];
  int _total = 0;
  String _searchQuery = '';

  static const _reportTypes = [
    {
      'key': 'attendance',
      'label': 'Attendance',
      'icon': Icons.access_time,
      'color': AppColors.success,
    },
    {
      'key': 'late',
      'label': 'Late Arrivals',
      'icon': Icons.warning_amber,
      'color': Color(0xFFF59E0B),
    },
    {
      'key': 'early_checkout',
      'label': 'Early Checkouts',
      'icon': Icons.logout,
      'color': AppColors.danger,
    },
    {
      'key': 'absence',
      'label': 'Absence',
      'icon': Icons.person_off,
      'color': Color(0xFFEF4444),
    },
    {
      'key': 'leave',
      'label': 'Leave Requests',
      'icon': Icons.event_note,
      'color': AppColors.info,
    },
    {
      'key': 'overtime',
      'label': 'Overtime',
      'icon': Icons.trending_up,
      'color': Color(0xFF8B5CF6),
    },
  ];

  static const _statusOptions = <String, List<String>>{
    'attendance': [
      'present',
      'absent',
      'late',
      'half_day',
      'on_leave',
      'holiday',
    ],
    'late': ['late', 'present'],
    'early_checkout': ['present', 'late', 'early_leave'],
    'absence': ['absent', 'on_leave', 'holiday'],
    'leave': ['pending', 'approved', 'rejected', 'cancelled'],
    'overtime': ['present', 'approved'],
  };

  static const _statusColors = <String, Color>{
    'present': AppColors.success,
    'approved': AppColors.success,
    'late': Color(0xFFF59E0B),
    'pending': Color(0xFFF59E0B),
    'absent': AppColors.danger,
    'rejected': AppColors.danger,
    'cancelled': AppColors.grey400,
    'on_leave': AppColors.info,
    'holiday': Color(0xFF8B5CF6),
    'half_day': AppColors.info,
    'early_leave': AppColors.danger,
  };

  static const _dateCols = {
    'date',
    'start_date',
    'end_date',
    'clock_in',
    'clock_out',
  };
  static const _statusCols = {'status', 'source'};

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    try {
      final result = await AdminOperationsRepository().getReportFilters();
      if (mounted) {
        setState(() {
          _departments = result['departments'] ?? [];
          _branches = result['branches'] ?? [];
          _employees = result['employees'] ?? [];
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic> _getActiveType() {
    return _reportTypes.firstWhere((r) => r['key'] == _selectedType);
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    DateTime from;
    switch (preset) {
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
    setState(() {
      _dateFilter = preset;
      _dateFrom = from.toString().substring(0, 10);
      _dateTo = now.toString().substring(0, 10);
    });
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = '';
      _dateTo = '';
      _branchId = '';
      _departmentId = '';
      _employeeId = '';
      _statusFilter = '';
      _dateFilter = 'Month';
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_dateFrom.isNotEmpty) count++;
    if (_dateTo.isNotEmpty) count++;
    if (_branchId.isNotEmpty) count++;
    if (_departmentId.isNotEmpty) count++;
    if (_employeeId.isNotEmpty) count++;
    if (_statusFilter.isNotEmpty) count++;
    return count;
  }

  Map<String, dynamic> _getFilterParams() {
    final params = <String, dynamic>{};
    if (_dateFrom.isNotEmpty) params['date_from'] = _dateFrom;
    if (_dateTo.isNotEmpty) params['date_to'] = _dateTo;
    if (_branchId.isNotEmpty) params['branch_id'] = _branchId;
    if (_departmentId.isNotEmpty) params['department_id'] = _departmentId;
    if (_employeeId.isNotEmpty) params['employee_id'] = _employeeId;
    if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
    return params;
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _generated = false;
    });
    try {
      final params = _getFilterParams();
      final result = await AdminOperationsRepository().generateReport(
        type: _selectedType,
        params: params,
      );
      setState(() {
        _isLoading = false;
        _generated = true;
        _records =
            (result['records'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _columns =
            (result['columns'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _summary =
            (result['summary'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _total = result['total'] ?? 0;
        _searchQuery = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _export(String format) async {
    setState(() {
      _isExporting = true;
    });
    try {
      final params = _getFilterParams();
      final path = await AdminOperationsRepository().exportReport(
        type: _selectedType,
        format: format,
        params: params,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reportExportSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.couldNotOpenFile(result.message),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.reportExportFailed(e.toString()),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records
        .where(
          (r) => r.values.any(
            (v) => v?.toString().toLowerCase().contains(q) ?? false,
          ),
        )
        .toList();
  }

  String _fmtDate(String? v) {
    if (v == null || v.isEmpty) return '—';
    final d = DateTime.tryParse(v);
    if (d == null) return v;
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _cellValue(Map<String, dynamic> col, dynamic raw) {
    if (raw == null || raw.toString().isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: 12, color: AppColors.grey400),
      );
    }
    final key = col['key'] as String;
    if (_dateCols.contains(key)) {
      return Text(
        _fmtDate(raw.toString()),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.grey700,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (_statusCols.contains(key)) {
      final val = raw.toString();
      final color = _statusColors[val.toLowerCase()] ?? AppColors.grey400;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          val.replaceAll('_', ' '),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }
    return Text(
      raw.toString(),
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.grey700,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeType = _getActiveType();
    final activeColor = activeType['color'] as Color;
    final activeIcon = activeType['icon'] as IconData;
    final activeLabel = activeType['label'] as String;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.reportsTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
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
            // ── Header card ──
            _buildHeaderCard(activeColor, activeIcon, activeLabel, l10n),
            const SizedBox(height: 16),

            // ── Report type tabs ──
            _buildReportTypeTabs(l10n),
            const SizedBox(height: 16),

            // ── Filters card ──
            _buildFiltersCard(l10n),
            const SizedBox(height: 16),

            // ── Loading state ──
            if (_isLoading) ...[
              _buildLoadingState(activeColor, activeIcon, activeLabel, l10n),
            ],

            // ── Empty state ──
            if (!_generated && !_isLoading) ...[
              _buildEmptyState(activeColor, activeIcon, activeLabel, l10n),
            ],

            // ── Results ──
            if (_generated && !_isLoading) ...[
              _buildResults(activeColor, activeIcon, activeLabel, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    Color color,
    IconData icon,
    String label,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Comprehensive breakdown by employee, department & branch',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          if (_generated && !_isLoading) ...[
            if (_isExporting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              PopupMenuButton<String>(
                icon: const Icon(Icons.download, color: AppColors.primary),
                tooltip: l10n.exportReportTooltip,
                onSelected: (fmt) => _export(fmt),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          size: 18,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 8),
                        Text('CSV / Excel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 8),
                        Text('PDF'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReportTypeTabs(AppLocalizations l10n) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _reportTypes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = _reportTypes[i];
          final isActive = _selectedType == r['key'];
          final color = r['color'] as Color;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = r['key'] as String;
                _generated = false;
                _statusFilter = '';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? color : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? color : AppColors.grey200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    r['icon'] as IconData,
                    size: 16,
                    color: isActive ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          // Filter header
          GestureDetector(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Report Filters & Criteria',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_activeFilterCount active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Icon(
                    _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date presets
                  Text(
                    'Quick Date Range',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Today', 'Week', 'Month', 'Year', 'All'].map((
                        preset,
                      ) {
                        final isActive =
                            _dateFilter == preset ||
                            (preset == 'All' && _dateFrom.isEmpty);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (preset == 'All') {
                                setState(() {
                                  _dateFilter = 'All';
                                  _dateFrom = '';
                                  _dateTo = '';
                                });
                              } else {
                                _applyDatePreset(preset);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withAlpha(26)
                                    : AppColors.grey50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.grey200,
                                ),
                              ),
                              child: Text(
                                preset == 'All' ? 'All Time' : preset,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'From',
                          _dateFrom,
                          (v) => setState(() {
                            _dateFrom = v;
                            _dateFilter = 'All';
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          'To',
                          _dateTo,
                          (v) => setState(() {
                            _dateTo = v;
                            _dateFilter = 'All';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Branch & Department
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Branch',
                          _branchId,
                          _branches,
                          'id',
                          'name',
                          'All Branches',
                          (v) => setState(() => _branchId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          'Department',
                          _departmentId,
                          _departments,
                          'id',
                          'name',
                          'All Departments',
                          (v) => setState(() => _departmentId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Employee & Status
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'Employee',
                          _employeeId,
                          _employees,
                          'id',
                          'full_name',
                          'All Employees',
                          (v) => setState(() => _employeeId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_activeFilterCount > 0)
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'Clear All Filters',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey500,
                            ),
                          ),
                        )
                      else
                        SizedBox(),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generate,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.trending_up, size: 16),
                          label: Text(
                            _isLoading ? 'Generating...' : 'Generate Report',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value.isNotEmpty
                  ? DateTime.tryParse(value) ?? DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(Duration(days: 365)),
            );
            if (d != null) onChanged(d.toString().substring(0, 10));
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
              color: AppColors.surfaceLight,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.grey400),
                const SizedBox(width: 8),
                Text(
                  value.isEmpty ? 'Select date' : value,
                  style: TextStyle(
                    fontSize: 12,
                    color: value.isEmpty
                        ? AppColors.grey400
                        : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<Map<String, dynamic>> items,
    String idKey,
    String labelKey,
    String allLabel,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.grey600,
          ),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
            color: AppColors.surfaceLight,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? '__all__' : value,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: '__all__',
                  child: Text(
                    allLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                ),
                ...items.map(
                  (item) => DropdownMenuItem(
                    value: item[idKey]?.toString() ?? '',
                    child: Text(
                      item[labelKey]?.toString() ?? 'Unknown',
                      style: TextStyle(fontSize: 12, color: AppColors.grey700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => onChanged(v == '__all__' ? '' : (v ?? '')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    final options = _statusOptions[_selectedType] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.grey600,
          ),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
            color: AppColors.surfaceLight,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter.isEmpty ? '__all__' : _statusFilter,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: '__all__',
                  child: Text(
                    'All Statuses',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                ),
                ...options.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 12, color: AppColors.grey700),
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(
                () => _statusFilter = v == '__all__' ? '' : (v ?? ''),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(
    Color color,
    IconData icon,
    String label,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating $label report...',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Calculating records and compiling breakdown',
            style: TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color color,
    IconData icon,
    String label,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          SizedBox(height: 16),
          Text(
            '$label Report',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select filters above and tap Generate Report to view detailed analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    Color color,
    IconData icon,
    String label,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary cards ──
        if (_summary.isNotEmpty) ...[
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _summary.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final card = _summary[i];
                return _buildSummaryCard(card);
              },
            ),
          ),
          SizedBox(height: 16),
        ],

        // ── Results container ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              // Result header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        SizedBox(width: 10),
                        Text(
                          '$label Results',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_total records',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search results...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grey400,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.grey100),

              // Records list
              if (_filteredRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 36,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No records match your filters.',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting the date range, branch, or department filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredRecords.map(
                  (record) => _buildRecordCard(record, color, _columns),
                ),

              if (_searchQuery.isNotEmpty &&
                  _filteredRecords.length < _records.length) ...[
                const Divider(height: 1, color: AppColors.grey100),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Showing ${_filteredRecords.length} of ${_records.length} records matching "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> card) {
    final colorMap = <String, Color>{
      'blue': AppColors.info,
      'green': AppColors.success,
      'amber': Color(0xFFF59E0B),
      'red': AppColors.danger,
      'purple': Color(0xFF8B5CF6),
      'indigo': Color(0xFF6366F1),
      'teal': Color(0xFF14B8A6),
      'orange': AppColors.primary,
    };
    final color = colorMap[card['color']?.toString()] ?? AppColors.grey400;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card['label']?.toString().toUpperCase() ?? '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card['value']?.toString() ?? '0',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    Map<String, dynamic> record,
    Color themeColor,
    List<Map<String, dynamic>> columns,
  ) {
    // Use columns to build display; first column is the title
    String title = record['full_name']?.toString() ?? 'Record';
    String? subtitle = record['emp_code']?.toString();

    // Build remaining fields from columns
    final displayCols = columns.where((c) {
      final key = c['key'] as String;
      return key != 'full_name' && key != 'emp_code';
    }).toList();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (record['status'] != null)
                  _cellValue({'key': 'status'}, record['status']),
              ],
            ),
          ),
          if (displayCols.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.grey100),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 16;
                  final double itemWidth = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 12,
                    children: displayCols.map((col) {
                      final key = col['key'] as String;
                      final label = col['label'] as String;
                      final raw = record[key];
                      return SizedBox(
                        width: itemWidth > 110
                            ? itemWidth
                            : constraints.maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _cellValue(col, raw),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
