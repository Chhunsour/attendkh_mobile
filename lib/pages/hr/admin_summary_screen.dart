import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/summary_repository.dart';
import 'package:attendkh/services/network/dio_client.dart';

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
  int _selectedYear = DateTime.now().year;
  bool _isOvertimeTableView = true; // Default to Web-like Table View
  bool _isPayrollTableView = true; // Default to Web-like Table View
  bool _isExpenseTableView = true; // Default to Web-like Table View
  bool _isPerformanceTableView = true; // Default to Web-like Table View
  bool _isRecruitmentTableView = true; // Default to Web-like Table View
  bool _isTrainingTableView = true; // Default to Web-like Table View

  String? _resolvePhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    final base = DioClient.storageUrl;
    final cleanPath = clean.startsWith('/') ? clean.substring(1) : clean;
    return '$base/$cleanPath';
  }

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
      } else if (type == 'leave') {
        filters['year'] = _selectedYear;
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

  Future<void> _pickMonth() async {
    int year = _selectedMonth.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setModalState(() => year--),
                  ),
                  Text(
                    '$year',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setModalState(() => year++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected =
                      year == _selectedMonth.year && month == _selectedMonth.month;
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, DateTime(year, month, 1)),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.grey800 : AppColors.grey100),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DateFormat('MMM').format(DateTime(2000, month)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      _loadSummary('attendance');
    }
  }

  void _changeYear(int offset) {
    if (_selectedType == null) return;
    setState(() {
      _selectedYear += offset;
    });
    _loadSummary(_selectedType!);
  }

  Future<void> _pickYear() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - 5 + i);

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Calendar Year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: years.map((y) {
                final isSelected = y == _selectedYear;
                return ChoiceChip(
                  label: Text(
                    '$y',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) Navigator.pop(ctx, y);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedYear = picked);
      _loadSummary('leave');
    }
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
        return const Color(0xFFF97316);
      case 'on_leave':
        return const Color(0xFF3B82F6);
      case 'holiday':
        return const Color(0xFF8B5CF6);
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
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Specialized Attendance Summary View (Matching Web) ────────────────────
  Widget _buildAttendanceSummaryView(bool isDark) {
    final daysInMonth =
        _fullResponse['daysInMonth'] as int? ??
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    int totalPresent = 0;
    int totalLate = 0;
    int totalAbsent = 0;
    int totalLeave = 0;

    for (final row in _data) {
      final totals = (row['totals'] as Map<String, dynamic>?) ?? {};
      totalPresent += int.tryParse(totals['present']?.toString() ?? '0') ?? 0;
      totalLate += int.tryParse(totals['late']?.toString() ?? '0') ?? 0;
      totalAbsent += int.tryParse(totals['absent']?.toString() ?? '0') ?? 0;
      totalLeave += int.tryParse(totals['on_leave']?.toString() ?? '0') ?? 0;
    }

    final totalStaff = _data.length;
    final workingOccurrences =
        totalPresent + totalLate + totalAbsent + totalLeave;
    final attendanceRate = workingOccurrences > 0
        ? (((totalPresent + totalLate) / workingOccurrences) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Month Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous Month',
              ),
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Next Month',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Executive KPI Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F2E23), const Color(0xFF064E3B)]
                  : [const Color(0xFF059669), const Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: (attendanceRate.clamp(0, 100)) / 100.0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Text(
                        '$attendanceRate%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MONTHLY ATTENDANCE RATE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          attendanceRate >= 90
                              ? 'Excellent Reliability'
                              : 'Attendance Needs Attention',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$totalStaff active staff tracked',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Present', '$totalPresent', Colors.white),
                    _buildStatPill('Late', '$totalLate', const Color(0xFFFBBF24)),
                    _buildStatPill('Absent', '$totalAbsent', const Color(0xFFF87171)),
                    _buildStatPill('Leave', '$totalLeave', const Color(0xFF60A5FA)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Legend Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLegendItem('P', 'Present', const Color(0xFF10B981)),
              _buildLegendItem('L', 'Late', const Color(0xFFF59E0B)),
              _buildLegendItem('A', 'Absent', const Color(0xFFEF4444)),
              _buildLegendItem('H', 'Half Day', const Color(0xFFF97316)),
              _buildLegendItem('V', 'Leave', const Color(0xFF3B82F6)),
              _buildLegendItem('W', 'Weekend', AppColors.grey400),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, department...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 5. Record count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MONTHLY ATTENDANCE SPREADSHEET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textSecondary(context),
              ),
            ),
            Text(
              '${_filteredData.length} staff',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 6. Synchronized Spreadsheet Table
        _buildSynchronizedAttendanceMatrix(daysInMonth, isDark),
      ],
    );
  }

  // ── Synchronized Attendance Spreadsheet Grid (Sticky Pinned Left Column) ──
  Widget _buildSynchronizedAttendanceMatrix(int daysInMonth, bool isDark) {
    const double employeeColWidth = 140.0;
    const double dayColWidth = 28.0;
    const double totalColWidth = 32.0;
    const double headerHeight = 36.0;
    const double rowHeight = 44.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final emp = row['employee'] as Map<String, dynamic>? ?? {};
                    final photoUrl = _resolvePhotoUrl(emp['photo_url']?.toString());
                    final name = emp['full_name']?.toString() ?? 'Employee';
                    final empId = emp['employee_id']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Synchronized Scrollable Day Matrix (1..31 + Totals) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: (daysInMonth * dayColWidth) + (4 * totalColWidth),
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            ...List.generate(daysInMonth, (i) {
                              final day = i + 1;
                              return Container(
                                width: dayColWidth,
                                alignment: Alignment.center,
                                child: Text(
                                  '$day',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            }),
                            _buildMatrixHeaderCell(
                                'P', const Color(0xFF10B981), totalColWidth),
                            _buildMatrixHeaderCell(
                                'L', const Color(0xFFF59E0B), totalColWidth),
                            _buildMatrixHeaderCell(
                                'A', const Color(0xFFEF4444), totalColWidth),
                            _buildMatrixHeaderCell(
                                'V', const Color(0xFF3B82F6), totalColWidth),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final days =
                            (row['days'] as Map<String, dynamic>?) ?? {};
                        final totals =
                            (row['totals'] as Map<String, dynamic>?) ?? {};
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              ...List.generate(daysInMonth, (i) {
                                final dayStr = (i + 1).toString();
                                final status = days[dayStr];
                                final color = _getStatusColor(status);
                                final label = _getStatusLabel(status);

                                return Container(
                                  width: dayColWidth,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              _buildMatrixTotalCell(
                                  '${totals['present'] ?? 0}',
                                  const Color(0xFF10B981),
                                  totalColWidth),
                              _buildMatrixTotalCell(
                                  '${totals['late'] ?? 0}',
                                  const Color(0xFFF59E0B),
                                  totalColWidth),
                              _buildMatrixTotalCell(
                                  '${totals['absent'] ?? 0}',
                                  const Color(0xFFEF4444),
                                  totalColWidth),
                              _buildMatrixTotalCell(
                                  '${totals['on_leave'] ?? 0}',
                                  const Color(0xFF3B82F6),
                                  totalColWidth),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixHeaderCell(String label, Color color, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMatrixTotalCell(String val, Color color, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border(left: BorderSide(color: color.withValues(alpha: 0.15))),
      ),
      child: Text(
        val,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  // ── Specialized Leave Summary View ─────────────────────────────────────────
  Widget _buildLeaveSummaryView(bool isDark) {
    double totalAllocated = 0;
    double totalUsed = 0;
    double totalRemaining = 0;
    int totalPending = 0;

    for (final row in _data) {
      totalAllocated +=
          double.tryParse(row['allocated_days']?.toString() ?? '0') ?? 0;
      totalUsed += double.tryParse(row['used_days']?.toString() ?? '0') ?? 0;
      totalRemaining +=
          double.tryParse(row['remaining_days']?.toString() ?? '0') ?? 0;
      totalPending +=
          int.tryParse(row['pending_requests']?.toString() ?? '0') ?? 0;
    }

    final utilizationRate = totalAllocated > 0
        ? ((totalUsed / totalAllocated) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Year Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeYear(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous Year',
              ),
              InkWell(
                onTap: _pickYear,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_selectedYear Leave Period',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeYear(1),
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
                tooltip: 'Next Year',
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Executive Metric Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: (utilizationRate.clamp(0, 100)) / 100.0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$utilizationRate%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LEAVE CONSUMPTION RATE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          utilizationRate <= 50
                              ? 'Healthy Leave Reserves'
                              : 'Moderate / High Utilization',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Total ${_data.length} leave records tracked',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill(
                      'Allocated',
                      '${totalAllocated.toStringAsFixed(0)}d',
                      Colors.white,
                    ),
                    _buildStatPill(
                      'Used',
                      '${totalUsed.toStringAsFixed(0)}d',
                      const Color(0xFFFBBF24),
                    ),
                    _buildStatPill(
                      'Remaining',
                      '${totalRemaining.toStringAsFixed(0)}d',
                      const Color(0xFF34D399),
                    ),
                    _buildStatPill(
                      'Pending',
                      '$totalPending',
                      const Color(0xFFF87171),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, department, leave type...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 4. Record count & List of Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EMPLOYEE LEAVE SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textSecondary(context),
              ),
            ),
            Text(
              '${_filteredData.length} records',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No leave records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else
          ..._filteredData.map((row) => _buildLeaveCard(row, isDark)),
      ],
    );
  }

  // ── Specialized Overtime Summary View (Matching Web) ──────────────────────
  Widget _buildOvertimeSummaryView(bool isDark) {
    int totalRequests = 0;
    double totalHours = 0;
    double totalCost = 0;
    int totalPending = 0;

    for (final row in _data) {
      totalRequests += int.tryParse(row['total_requests']?.toString() ?? '0') ?? 0;
      totalHours += double.tryParse(row['total_hours']?.toString() ?? '0') ?? 0;
      totalCost += double.tryParse(row['total_cost']?.toString() ?? '0') ?? 0;
      totalPending += int.tryParse(row['pending_count']?.toString() ?? '0') ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Executive Overtime Banner (Matching Leave & Attendance)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF3B1E08), const Color(0xFF231204)]
                  : [const Color(0xFFEA580C), const Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OVERTIME & ACCRUED PAYROLL',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)} Accrued',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${totalHours.toStringAsFixed(1)} total hours across $totalRequests requests',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Requests', '$totalRequests', Colors.white),
                    _buildStatPill('OT Hours', '${totalHours.toStringAsFixed(1)}h', const Color(0xFFFDE047)),
                    _buildStatPill('Accrued Cost', '\$${totalCost.toStringAsFixed(0)}', const Color(0xFF86EFAC)),
                    _buildStatPill('Pending', '$totalPending', const Color(0xFFFCA5A5)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, department, period...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERTIME BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOvertimeViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isOvertimeTableView,
                    onTap: () => setState(() => _isOvertimeTableView = true),
                  ),
                  _buildOvertimeViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isOvertimeTableView,
                    onTap: () => setState(() => _isOvertimeTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No overtime records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isOvertimeTableView)
          // ── Synchronized Table View (Matching Web) ──
          _buildOvertimeTableView(isDark)
        else
          // ── Clean Executive Card List View ──
          ..._filteredData.map((row) => _buildOvertimeCard(row, isDark)),
      ],
    );
  }

  Widget _buildOvertimeViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Overtime Table (Matching Web Spreadsheet Columns) ─────────
  Widget _buildOvertimeTableView(bool isDark) {
    const double employeeColWidth = 140.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());
                    final name = row['full_name']?.toString() ?? 'Employee';
                    final empId = row['emp_code']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF97316).withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF97316),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF97316),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 440,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Period', 65),
                            _buildOtThCell('Reqs', 45),
                            _buildOtThCell('Approved', 65),
                            _buildOtThCell('Pending', 65),
                            _buildOtThCell('Rejected', 65),
                            _buildOtThCell('OT Hours', 65),
                            _buildOtThCell('Accrued Cost', 70),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final period = row['period']?.toString() ?? '-';
                        final totalReq = int.tryParse(row['total_requests']?.toString() ?? '0') ?? 0;
                        final approved = int.tryParse(row['approved_count']?.toString() ?? '0') ?? 0;
                        final pending = int.tryParse(row['pending_count']?.toString() ?? '0') ?? 0;
                        final rejected = int.tryParse(row['rejected_count']?.toString() ?? '0') ?? 0;
                        final hours = double.tryParse(row['total_hours']?.toString() ?? '0') ?? 0;
                        final cost = double.tryParse(row['total_cost']?.toString() ?? '0') ?? 0;
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildOtTdText(period, 65),
                              _buildOtTdText('$totalReq', 45, isBold: true),
                              _buildOtTdBadge('$approved', const Color(0xFF10B981), 65),
                              _buildOtTdBadge('$pending', const Color(0xFFF59E0B), 65),
                              _buildOtTdBadge('$rejected', const Color(0xFFEF4444), 65),
                              _buildOtTdText('${hours.toStringAsFixed(1)}h', 65, color: const Color(0xFFF97316), isBold: true),
                              _buildOtTdText('\$${cost.toStringAsFixed(2)}', 70, isBold: true),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtThCell(String label, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.grey600,
        ),
      ),
    );
  }

  Widget _buildOtTdText(String val, double width, {bool isBold = false, Color? color}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        val,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          color: color ?? AppColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildOtTdBadge(String val, Color color, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          val,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }



  // ── Clean & Simplified Executive Card ──────────────────────────────────────
  Widget _buildOvertimeCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '';
    final period = row['period']?.toString() ?? '-';
    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());

    final approved = int.tryParse(row['approved_count']?.toString() ?? '0') ?? 0;
    final pending = int.tryParse(row['pending_count']?.toString() ?? '0') ?? 0;
    final rejected = int.tryParse(row['rejected_count']?.toString() ?? '0') ?? 0;

    final hours = double.tryParse(row['total_hours']?.toString() ?? '0') ?? 0;
    final cost = double.tryParse(row['total_cost']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar, Name, Department & Period Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF97316),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF97316),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept${branch.isNotEmpty ? ' • $branch' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Hero Highlight Box: OT Hours + Accrued Cost side by side
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'TOTAL OT HOURS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hours.toStringAsFixed(1)} hrs',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                Column(
                  children: [
                    const Text(
                      'ACCRUED COST',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${cost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Status Breakdown Chips
          Row(
            children: [
              _buildMiniStatusBadge('Approved', '$approved', const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _buildMiniStatusBadge('Pending', '$pending', const Color(0xFFF59E0B)),
              if (rejected > 0) ...[
                const SizedBox(width: 6),
                _buildMiniStatusBadge('Rejected', '$rejected', const Color(0xFFEF4444)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── PAYROLL SUMMARY VIEW ───────────────────────────────────────────────────

  Widget _buildPayrollSummaryView(bool isDark) {
    double totalGross = 0;
    double totalNet = 0;
    double totalDeductions = 0;
    int totalCount = _data.length;

    for (final row in _data) {
      totalGross += double.tryParse(row['gross_salary']?.toString() ?? '0') ?? 0;
      totalNet += double.tryParse(row['net_salary']?.toString() ?? '0') ?? 0;
      totalDeductions += double.tryParse(row['total_deductions']?.toString() ?? '0') ?? 0;
    }

    final double avgNet = totalCount > 0 ? (totalNet / totalCount) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Executive Payroll Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF332604), const Color(0xFF1E1702)]
                  : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYROLL & COMPENSATION',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${totalNet.toStringAsFixed(2)} Disbursed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Gross: \$${totalGross.toStringAsFixed(2)} • Deductions: \$${totalDeductions.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Total Gross', '\$${totalGross.toStringAsFixed(0)}', Colors.white),
                    _buildStatPill('Net Payout', '\$${totalNet.toStringAsFixed(0)}', const Color(0xFF86EFAC)),
                    _buildStatPill('Deductions', '\$${totalDeductions.toStringAsFixed(0)}', const Color(0xFFFCA5A5)),
                    _buildStatPill('Avg/Staff', '\$${avgNet.toStringAsFixed(0)}', const Color(0xFFFDE047)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, department, period...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYROLL BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPayrollViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isPayrollTableView,
                    onTap: () => setState(() => _isPayrollTableView = true),
                  ),
                  _buildPayrollViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isPayrollTableView,
                    onTap: () => setState(() => _isPayrollTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No payroll records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isPayrollTableView)
          _buildPayrollTableView(isDark)
        else
          ..._filteredData.map((row) => _buildPayrollCard(row, isDark)),
      ],
    );
  }

  Widget _buildPayrollViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Payroll Table View (Matching Web Spreadsheet Columns) ─────
  Widget _buildPayrollTableView(bool isDark) {
    const double employeeColWidth = 140.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());
                    final name = row['full_name']?.toString() ?? 'Employee';
                    final empId = row['emp_code']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 530,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Period', 65),
                            _buildOtThCell('Basic', 70),
                            _buildOtThCell('OT Pay', 65),
                            _buildOtThCell('Allowances', 70),
                            _buildOtThCell('Gross', 75),
                            _buildOtThCell('Deductions', 75),
                            _buildOtThCell('Net Take-Home', 90),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final period = row['period']?.toString() ?? '-';
                        final basic = double.tryParse(row['basic_salary']?.toString() ?? '0') ?? 0;
                        final otPay = double.tryParse(row['overtime_pay']?.toString() ?? '0') ?? 0;
                        final allowances = double.tryParse(row['allowances']?.toString() ?? '0') ?? 0;
                        final gross = double.tryParse(row['gross_salary']?.toString() ?? '0') ?? 0;
                        final deductions = double.tryParse(row['total_deductions']?.toString() ?? '0') ?? 0;
                        final net = double.tryParse(row['net_salary']?.toString() ?? '0') ?? 0;
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildOtTdText(period, 65),
                              _buildOtTdText('\$${basic.toStringAsFixed(0)}', 70),
                              _buildOtTdText(otPay > 0 ? '\$${otPay.toStringAsFixed(0)}' : '—', 65, color: const Color(0xFF6366F1)),
                              _buildOtTdText(allowances > 0 ? '\$${allowances.toStringAsFixed(0)}' : '—', 70),
                              _buildOtTdText('\$${gross.toStringAsFixed(2)}', 75, isBold: true, color: const Color(0xFF3B82F6)),
                              _buildOtTdText('\$${deductions.toStringAsFixed(2)}', 75, color: const Color(0xFFEF4444)),
                              _buildOtTdBadge('\$${net.toStringAsFixed(2)}', const Color(0xFF10B981), 90),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean & Simplified Executive Payroll Card ──────────────────────────────
  Widget _buildPayrollCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '';
    final period = row['period']?.toString() ?? '-';
    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());

    final basic = double.tryParse(row['basic_salary']?.toString() ?? '0') ?? 0;
    final otPay = double.tryParse(row['overtime_pay']?.toString() ?? '0') ?? 0;
    final otHours = double.tryParse(row['overtime_hours']?.toString() ?? '0') ?? 0;
    final allowances = double.tryParse(row['allowances']?.toString() ?? '0') ?? 0;
    final gross = double.tryParse(row['gross_salary']?.toString() ?? '0') ?? 0;
    final tax = double.tryParse(row['tax_deduction']?.toString() ?? '0') ?? 0;
    final nssf = double.tryParse(row['insurance_deduction']?.toString() ?? '0') ?? 0;
    final deductions = double.tryParse(row['total_deductions']?.toString() ?? '0') ?? 0;
    final net = double.tryParse(row['net_salary']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar, Name, Department & Period Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept${branch.isNotEmpty ? ' • $branch' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Hero Highlight Box: Gross Salary vs Net Take-Home
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'GROSS EARNINGS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${gross.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                Column(
                  children: [
                    const Text(
                      'NET TAKE-HOME',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${net.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Compensation Breakdown Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Basic: \$${basic.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                if (otPay > 0)
                  Text(
                    'OT: \$${otPay.toStringAsFixed(0)}${otHours > 0 ? ' (${otHours.toStringAsFixed(0)}h)' : ''}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                  ),
                if (allowances > 0)
                  Text(
                    'Allowances: \$${allowances.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                Text(
                  'Deductions: -\$${deductions.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
          if (tax > 0 || nssf > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tax > 0)
                  Text(
                    'Tax: \$${tax.toStringAsFixed(2)}  ',
                    style: const TextStyle(fontSize: 9.5, color: AppColors.grey500),
                  ),
                if (nssf > 0)
                  Text(
                    'NSSF: \$${nssf.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 9.5, color: AppColors.grey500),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── RECRUITMENT SUMMARY VIEW ───────────────────────────────────────────────

  Widget _buildRecruitmentSummaryView(bool isDark) {
    int totalPostings = _data.length;
    int openPostings = 0;
    int totalApplicants = 0;
    int totalHired = 0;
    int totalInterviewed = 0;
    int totalOffered = 0;

    for (final row in _data) {
      if (row['status']?.toString().toLowerCase() == 'open') {
        openPostings++;
      }
      totalApplicants += int.tryParse(row['total_applicants']?.toString() ?? '0') ?? 0;
      totalHired += int.tryParse(row['hired']?.toString() ?? '0') ?? 0;
      totalInterviewed += int.tryParse(row['interviewed']?.toString() ?? '0') ?? 0;
      totalOffered += int.tryParse(row['offered']?.toString() ?? '0') ?? 0;
    }

    final overallConversion = totalApplicants > 0 ? (totalHired / totalApplicants * 100).toStringAsFixed(1) : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Blue/Sky Executive Recruitment Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TALENT ACQUISITION & PIPELINE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$totalPostings Postings',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($openPostings open)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Pipeline: $totalApplicants applicants • $totalInterviewed intv • $totalOffered offer • $totalHired hired ($overallConversion%)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Total Jobs', '$totalPostings', Colors.white),
                    _buildStatPill('Applicants', '$totalApplicants', const Color(0xFFBAE6FD)),
                    _buildStatPill('Interviewed', '$totalInterviewed', const Color(0xFFFDE047)),
                    _buildStatPill('Hired', '$totalHired', const Color(0xFF86EFAC)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search job title, department, position...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOB POSTINGS & FUNNEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRecruitmentViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isRecruitmentTableView,
                    onTap: () => setState(() => _isRecruitmentTableView = true),
                  ),
                  _buildRecruitmentViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isRecruitmentTableView,
                    onTap: () => setState(() => _isRecruitmentTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No recruitment job postings found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isRecruitmentTableView)
          _buildRecruitmentTableView(isDark)
        else
          ..._filteredData.map((row) => _buildRecruitmentCard(row, isDark)),
      ],
    );
  }

  Widget _buildRecruitmentViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Recruitment Table View ────────────────────────────────────
  Widget _buildRecruitmentTableView(bool isDark) {
    const double jobColWidth = 150.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Job Title & Position ──
            SizedBox(
              width: jobColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'JOB POSTING',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final title = row['job_title']?.toString() ?? 'Job Title';
                    final position = row['position']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.work_outline_rounded,
                                size: 14,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  position,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 580,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Department', 95),
                            _buildOtThCell('Type', 75),
                            _buildOtThCell('Openings', 65),
                            _buildOtThCell('Applicants', 75),
                            _buildOtThCell('Interviewed', 75),
                            _buildOtThCell('Offered', 65),
                            _buildOtThCell('Hired', 60),
                            _buildOtThCell('Conv %', 65),
                            _buildOtThCell('Status', 70),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final dept = row['department']?.toString() ?? '-';
                        final type = (row['employment_type']?.toString() ?? 'full_time').replaceAll('_', ' ').toUpperCase();
                        final openings = row['positions_available']?.toString() ?? '1';
                        final applicants = row['total_applicants']?.toString() ?? '0';
                        final interviewed = row['interviewed']?.toString() ?? '0';
                        final offered = row['offered']?.toString() ?? '0';
                        final hired = row['hired']?.toString() ?? '0';
                        final conv = double.tryParse(row['conversion_rate']?.toString() ?? '0') ?? 0.0;
                        final status = row['status']?.toString().toLowerCase() ?? 'open';
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildOtTdText(dept, 95),
                              Container(
                                width: 75,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.grey800 : AppColors.grey200).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              _buildOtTdText(openings, 65),
                              _buildOtTdBadge(applicants, const Color(0xFF6366F1), 75),
                              _buildOtTdBadge(interviewed, const Color(0xFFF59E0B), 75),
                              _buildOtTdBadge(offered, const Color(0xFF0284C7), 65),
                              _buildOtTdBadge(hired, const Color(0xFF10B981), 60),
                              Container(
                                width: 65,
                                alignment: Alignment.center,
                                child: Text(
                                  '${conv.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                              _buildOtTdBadge(
                                status.toUpperCase(),
                                status == 'open'
                                    ? const Color(0xFF10B981)
                                    : (status == 'closed'
                                        ? const Color(0xFFEF4444)
                                        : (status == 'filled'
                                            ? const Color(0xFF3B82F6)
                                            : AppColors.grey500)),
                                70,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean & Simplified Executive Recruitment Card ──────────────────────────
  Widget _buildRecruitmentCard(Map<String, dynamic> row, bool isDark) {
    final title = row['job_title']?.toString() ?? 'Job Title';
    final dept = row['department']?.toString() ?? '-';
    final position = row['position']?.toString() ?? '-';
    final type = (row['employment_type']?.toString() ?? 'full_time').replaceAll('_', ' ').toUpperCase();
    final openings = int.tryParse(row['positions_available']?.toString() ?? '1') ?? 1;
    final closingDate = row['closing_date']?.toString() ?? '-';
    final applicants = int.tryParse(row['total_applicants']?.toString() ?? '0') ?? 0;
    final interviewed = int.tryParse(row['interviewed']?.toString() ?? '0') ?? 0;
    final offered = int.tryParse(row['offered']?.toString() ?? '0') ?? 0;
    final hired = int.tryParse(row['hired']?.toString() ?? '0') ?? 0;
    final conv = double.tryParse(row['conversion_rate']?.toString() ?? '0') ?? 0.0;
    final status = row['status']?.toString().toLowerCase() ?? 'open';

    Color statusColor;
    switch (status) {
      case 'open':
        statusColor = const Color(0xFF10B981);
        break;
      case 'closed':
        statusColor = const Color(0xFFEF4444);
        break;
      case 'filled':
        statusColor = const Color(0xFF3B82F6);
        break;
      default:
        statusColor = AppColors.grey500;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon, Job Title, Dept, Position & Type Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.work_outline_rounded,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$position • $dept',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Hero Funnel Box: Total Applicants vs Hired + Conversion Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'TOTAL APPLICANTS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$applicants',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                Column(
                  children: [
                    const Text(
                      'HIRED (CONVERSION)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hired (${conv.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Funnel Stages Breakdown Chips
          Row(
            children: [
              _buildMiniStatusBadge('Interviewed', '$interviewed', const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _buildMiniStatusBadge('Offered', '$offered', const Color(0xFF0284C7)),
              const SizedBox(width: 6),
              _buildMiniStatusBadge('Slots', '$openings', const Color(0xFF6366F1)),
              const Spacer(),
              _buildMiniStatusBadge(
                status.toUpperCase(),
                '●',
                statusColor,
              ),
            ],
          ),

          if (closingDate != '-') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_busy_rounded, size: 12, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  'Closing Date: $closingDate',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.grey500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── TRAINING SUMMARY VIEW ──────────────────────────────────────────────────

  Widget _buildTrainingSummaryView(bool isDark) {
    int totalEnrollments = _data.length;
    int completedCount = 0;
    int inProgressCount = 0;
    double totalCompletedHours = 0;
    int totalProgressSum = 0;

    for (final row in _data) {
      final status = row['status']?.toString().toLowerCase();
      if (status == 'completed') {
        completedCount++;
      } else if (status == 'in_progress') {
        inProgressCount++;
      }
      totalCompletedHours += double.tryParse(row['completed_hours']?.toString() ?? '0') ?? 0;
      totalProgressSum += int.tryParse(row['progress_percentage']?.toString() ?? '0') ?? 0;
    }

    final avgProgress = totalEnrollments > 0 ? (totalProgressSum / totalEnrollments).round() : 0;
    final completionRate = totalEnrollments > 0 ? (completedCount / totalEnrollments * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Emerald/Teal Executive Training Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                  : [const Color(0xFF059669), const Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRAINING & PROFESSIONAL DEVELOPMENT',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$totalEnrollments Enrollments',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($completedCount completed)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Progress: $avgProgress% avg • $totalCompletedHours hrs completed • $completionRate% completion rate',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Enrollments', '$totalEnrollments', Colors.white),
                    _buildStatPill('Completed', '$completedCount', const Color(0xFF86EFAC)),
                    _buildStatPill('In Progress', '$inProgressCount', const Color(0xFFFDE047)),
                    _buildStatPill('Hours', '${totalCompletedHours.toStringAsFixed(0)}h', const Color(0xFFBAE6FD)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, course, category, status...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAINING ENROLLMENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrainingViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isTrainingTableView,
                    onTap: () => setState(() => _isTrainingTableView = true),
                  ),
                  _buildTrainingViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isTrainingTableView,
                    onTap: () => setState(() => _isTrainingTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No training enrollment records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isTrainingTableView)
          _buildTrainingTableView(isDark)
        else
          ..._filteredData.map((row) => _buildTrainingCard(row, isDark)),
      ],
    );
  }

  Widget _buildTrainingViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Training Table View ───────────────────────────────────────
  Widget _buildTrainingTableView(bool isDark) {
    const double employeeColWidth = 140.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());
                    final name = row['full_name']?.toString() ?? 'Employee';
                    final empId = row['emp_code']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 580,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Course Title', 140),
                            _buildOtThCell('Category', 90),
                            _buildOtThCell('Duration', 65),
                            _buildOtThCell('Progress', 85),
                            _buildOtThCell('Score', 60),
                            _buildOtThCell('Status', 70),
                            _buildOtThCell('Completed', 70),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final course = row['training_title']?.toString() ?? 'Course';
                        final category = row['training_category']?.toString() ?? '-';
                        final duration = '${row['duration_hours'] ?? 0} hrs';
                        final progress = int.tryParse(row['progress_percentage']?.toString() ?? '0') ?? 0;
                        final score = row['score'] != null ? '${row['score']}' : '—';
                        final scoreNum = int.tryParse(row['score']?.toString() ?? '');
                        final status = row['status']?.toString().toLowerCase() ?? 'enrolled';
                        final completedDate = row['completed_at']?.toString() ?? '—';
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  course,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildOtTdText(category, 90),
                              _buildOtTdText(duration, 65),
                              Container(
                                width: 85,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          minHeight: 4,
                                          backgroundColor: AppColors.grey300,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            progress == 100 ? const Color(0xFF10B981) : const Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$progress%',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildOtTdBadge(
                                score,
                                scoreNum != null
                                    ? (scoreNum >= 80 ? const Color(0xFF10B981) : (scoreNum >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)))
                                    : AppColors.grey500,
                                60,
                              ),
                              _buildOtTdBadge(
                                status.replaceAll('_', ' ').toUpperCase(),
                                status == 'completed'
                                    ? const Color(0xFF10B981)
                                    : (status == 'in_progress'
                                        ? const Color(0xFFF59E0B)
                                        : (status == 'enrolled'
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFFEF4444))),
                                70,
                              ),
                              _buildOtTdText(completedDate != 'null' ? completedDate : '—', 70),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean & Simplified Executive Training Card ─────────────────────────────
  Widget _buildTrainingCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '';
    final course = row['training_title']?.toString() ?? 'Course';
    final category = row['training_category']?.toString() ?? '-';
    final duration = '${row['duration_hours'] ?? 0} hrs';
    final progress = int.tryParse(row['progress_percentage']?.toString() ?? '0') ?? 0;
    final score = row['score'] != null ? '${row['score']}' : null;
    final scoreNum = int.tryParse(row['score']?.toString() ?? '');
    final status = row['status']?.toString().toLowerCase() ?? 'enrolled';
    final enrolledAt = row['enrolled_at']?.toString() ?? '-';
    final completedAt = row['completed_at']?.toString();
    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'enrolled':
        statusColor = const Color(0xFF3B82F6);
        break;
      default:
        statusColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Employee Avatar, Name, Dept & Category Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept${branch.isNotEmpty ? ' • $branch' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Course Title & Duration
          Row(
            children: [
              Expanded(
                child: Text(
                  course,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. Hero Progress Box: Progress Bar vs Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'COURSE PROGRESS',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.grey500,
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.grey300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress == 100 ? const Color(0xFF10B981) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text(
                      'TEST SCORE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score != null ? '$score pts' : '—',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: scoreNum != null
                            ? (scoreNum >= 80 ? const Color(0xFF10B981) : (scoreNum >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)))
                            : AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. Dates & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 12, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    'Enrolled: $enrolledAt${completedAt != null && completedAt != 'null' ? ' • Done: $completedAt' : ''}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.grey500),
                  ),
                ],
              ),
              _buildMiniStatusBadge(
                status.replaceAll('_', ' ').toUpperCase(),
                '●',
                statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PERFORMANCE SUMMARY VIEW ───────────────────────────────────────────────

  Widget _buildPerformanceSummaryView(bool isDark) {
    int totalReviews = _data.length;
    double sumRating = 0;
    int completedReviews = 0;
    int totalKpis = 0;
    int completedKpis = 0;

    for (final row in _data) {
      final rating = double.tryParse(row['overall_rating']?.toString() ?? '0') ?? 0;
      sumRating += rating;
      if (row['status']?.toString().toLowerCase() == 'completed') {
        completedReviews++;
      }
      totalKpis += int.tryParse(row['total_kpis']?.toString() ?? '0') ?? 0;
      completedKpis += int.tryParse(row['completed_kpis']?.toString() ?? '0') ?? 0;
    }

    final avgRating = totalReviews > 0 ? sumRating / totalReviews : 0.0;
    final kpiCompletion = totalKpis > 0 ? (completedKpis / totalKpis * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Executive Performance Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2E1065), const Color(0xFF1E1B4B)]
                  : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERFORMANCE & KPI EVALUATION',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              avgRating > 0 ? '${avgRating.toStringAsFixed(1)} ★' : 'N/A',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Avg Score',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Total: $totalReviews reviews • Met: $completedKpis/$totalKpis KPIs ($kpiCompletion%)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Reviews', '$totalReviews', Colors.white),
                    _buildStatPill('Avg Score', avgRating > 0 ? '${avgRating.toStringAsFixed(1)}★' : '—', const Color(0xFFFDE047)),
                    _buildStatPill('Completed', '$completedReviews', const Color(0xFF86EFAC)),
                    _buildStatPill('KPI Rate', '$kpiCompletion%', const Color(0xFF93C5FD)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, review type, period, status...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERFORMANCE REVIEWS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPerformanceViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isPerformanceTableView,
                    onTap: () => setState(() => _isPerformanceTableView = true),
                  ),
                  _buildPerformanceViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isPerformanceTableView,
                    onTap: () => setState(() => _isPerformanceTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No performance review records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isPerformanceTableView)
          _buildPerformanceTableView(isDark)
        else
          ..._filteredData.map((row) => _buildPerformanceCard(row, isDark)),
      ],
    );
  }

  Widget _buildPerformanceViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Performance Table View ────────────────────────────────────
  Widget _buildPerformanceTableView(bool isDark) {
    const double employeeColWidth = 140.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());
                    final name = row['full_name']?.toString() ?? 'Employee';
                    final empId = row['emp_code']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 480,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Review Type', 90),
                            _buildOtThCell('Period', 80),
                            _buildOtThCell('Review Date', 85),
                            _buildOtThCell('Rating', 70),
                            _buildOtThCell('KPIs Met', 75),
                            _buildOtThCell('Status', 80),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final reviewType = (row['review_type']?.toString() ?? 'Annual').replaceAll('_', ' ').toUpperCase();
                        final period = row['review_period']?.toString() ?? '-';
                        final date = row['review_date']?.toString() ?? '-';
                        final rating = double.tryParse(row['overall_rating']?.toString() ?? '0') ?? 0;
                        final totalKpi = int.tryParse(row['total_kpis']?.toString() ?? '0') ?? 0;
                        final completedKpi = int.tryParse(row['completed_kpis']?.toString() ?? '0') ?? 0;
                        final status = row['status']?.toString().toLowerCase() ?? 'draft';
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 90,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.grey800 : AppColors.grey200).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    reviewType,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              _buildOtTdText(period, 80),
                              _buildOtTdText(date, 85),
                              Container(
                                width: 70,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (rating >= 4.0 ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: rating >= 4.0 ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating > 0 ? rating.toStringAsFixed(1) : '—',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: rating >= 4.0 ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildOtTdBadge('$completedKpi / $totalKpi', const Color(0xFF10B981), 75),
                              _buildOtTdBadge(
                                status.toUpperCase(),
                                status == 'completed'
                                    ? const Color(0xFF10B981)
                                    : (status == 'submitted'
                                        ? const Color(0xFF3B82F6)
                                        : (status == 'acknowledged'
                                            ? const Color(0xFFF59E0B)
                                            : AppColors.grey500)),
                                80,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean & Simplified Executive Performance Card ──────────────────────────
  Widget _buildPerformanceCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '';
    final reviewType = (row['review_type']?.toString() ?? 'Annual').replaceAll('_', ' ').toUpperCase();
    final period = row['review_period']?.toString() ?? '-';
    final reviewDate = row['review_date']?.toString() ?? '-';
    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());

    final rating = double.tryParse(row['overall_rating']?.toString() ?? '0') ?? 0;
    final totalKpis = int.tryParse(row['total_kpis']?.toString() ?? '0') ?? 0;
    final completedKpis = int.tryParse(row['completed_kpis']?.toString() ?? '0') ?? 0;
    final kpiPct = totalKpis > 0 ? (completedKpis / totalKpis * 100).round() : 0;
    final status = row['status']?.toString().toLowerCase() ?? 'draft';

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        break;
      case 'submitted':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'acknowledged':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = AppColors.grey500;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar, Name, Department & Review Type Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept${branch.isNotEmpty ? ' • $branch' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reviewType,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Hero Score Box: Overall Rating vs KPI Met Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'OVERALL RATING',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '—',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                Column(
                  children: [
                    const Text(
                      'KPI COMPLETION',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$kpiPct% ($completedKpis/$totalKpis)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Bottom Row: Period, Date & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    '$period • $reviewDate',
                    style: const TextStyle(fontSize: 11, color: AppColors.grey600),
                  ),
                ],
              ),
              _buildMiniStatusBadge(
                status.toUpperCase(),
                '●',
                statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EXPENSE SUMMARY VIEW ───────────────────────────────────────────────────

  Widget _buildExpenseSummaryView(bool isDark) {
    int totalClaims = 0;
    double totalAmount = 0;
    double totalApproved = 0;
    double totalPending = 0;
    double totalPaid = 0;

    for (final row in _data) {
      totalClaims += int.tryParse(row['total_claims']?.toString() ?? '0') ?? 0;
      totalAmount += double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0;
      totalApproved += double.tryParse(row['approved_amount']?.toString() ?? '0') ?? 0;
      totalPending += double.tryParse(row['pending_amount']?.toString() ?? '0') ?? 0;
      totalPaid += double.tryParse(row['paid_amount']?.toString() ?? '0') ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Unified Executive Expense Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF3B1219), const Color(0xFF220A0E)]
                  : [const Color(0xFFE11D48), const Color(0xFFF43F5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPENSE & REIMBURSEMENTS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)} Claimed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Approved: \$${totalApproved.toStringAsFixed(2)} • Disbursed: \$${totalPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Claims', '$totalClaims', Colors.white),
                    _buildStatPill('Approved', '\$${totalApproved.toStringAsFixed(0)}', const Color(0xFF86EFAC)),
                    _buildStatPill('Pending', '\$${totalPending.toStringAsFixed(0)}', const Color(0xFFFDE047)),
                    _buildStatPill('Paid Out', '\$${totalPaid.toStringAsFixed(0)}', const Color(0xFF93C5FD)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Search Bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search employee, category, department...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Record count & View Toggle Switcher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPENSE BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${_filteredData.length} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // View Mode Toggle Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildExpenseViewBtn(
                    icon: Icons.table_chart_rounded,
                    label: 'Table',
                    isSelected: _isExpenseTableView,
                    onTap: () => setState(() => _isExpenseTableView = true),
                  ),
                  _buildExpenseViewBtn(
                    icon: Icons.view_agenda_rounded,
                    label: 'Cards',
                    isSelected: !_isExpenseTableView,
                    onTap: () => setState(() => _isExpenseTableView = false),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_filteredData.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Text(
              'No expense records found',
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
          )
        else if (_isExpenseTableView)
          _buildExpenseTableView(isDark)
        else
          ..._filteredData.map((row) => _buildExpenseCard(row, isDark)),
      ],
    );
  }

  Widget _buildExpenseViewBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE11D48) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Synchronized Expense Table View (Matching Web Spreadsheet Columns) ─────
  Widget _buildExpenseTableView(bool isDark) {
    const double employeeColWidth = 140.0;
    const double headerHeight = 36.0;
    const double rowHeight = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left Pinned Column: Employee Details ──
            SizedBox(
              width: employeeColWidth,
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey900 : AppColors.grey100,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border(context)),
                        right: BorderSide(
                            color: AppColors.border(context), width: 1.5),
                      ),
                    ),
                    child: Text(
                      'EMPLOYEE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                  ..._filteredData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());
                    final name = row['full_name']?.toString() ?? 'Employee';
                    final empId = row['emp_code']?.toString() ?? '-';
                    final isEven = index % 2 == 0;

                    return Container(
                      height: rowHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.transparent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : AppColors.grey50),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.border(context), width: 0.5),
                          right: BorderSide(
                              color: AppColors.border(context), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                            ),
                            child: ClipOval(
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE11D48),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE11D48),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  empId,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.grey500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Right Pane: Scrollable Breakdown Columns (Matching Web) ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: 440,
                  child: Column(
                    children: [
                      Container(
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey900 : AppColors.grey100,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border(context)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildOtThCell('Category', 80),
                            _buildOtThCell('Claims', 50),
                            _buildOtThCell('Total', 75),
                            _buildOtThCell('Approved', 75),
                            _buildOtThCell('Pending', 75),
                            _buildOtThCell('Paid Out', 80),
                          ],
                        ),
                      ),
                      ..._filteredData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        final category = row['category']?.toString() ?? 'General';
                        final claims = int.tryParse(row['total_claims']?.toString() ?? '0') ?? 0;
                        final total = double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0;
                        final approved = double.tryParse(row['approved_amount']?.toString() ?? '0') ?? 0;
                        final pending = double.tryParse(row['pending_amount']?.toString() ?? '0') ?? 0;
                        final paid = double.tryParse(row['paid_amount']?.toString() ?? '0') ?? 0;
                        final isEven = index % 2 == 0;

                        return Container(
                          height: rowHeight,
                          decoration: BoxDecoration(
                            color: isEven
                                ? Colors.transparent
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : AppColors.grey50),
                            border: Border(
                              bottom: BorderSide(
                                  color: AppColors.border(context), width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.grey800 : AppColors.grey200).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              _buildOtTdText('$claims', 50, isBold: true),
                              _buildOtTdText('\$${total.toStringAsFixed(2)}', 75, isBold: true),
                              _buildOtTdBadge('\$${approved.toStringAsFixed(2)}', const Color(0xFF10B981), 75),
                              _buildOtTdBadge('\$${pending.toStringAsFixed(2)}', const Color(0xFFF59E0B), 75),
                              _buildOtTdBadge('\$${paid.toStringAsFixed(2)}', const Color(0xFF3B82F6), 80),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean & Simplified Executive Expense Card ──────────────────────────────
  Widget _buildExpenseCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '';
    final category = row['category']?.toString() ?? 'General';
    final photoUrl = _resolvePhotoUrl(row['photo_url']?.toString());

    final claims = int.tryParse(row['total_claims']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0;
    final approved = double.tryParse(row['approved_amount']?.toString() ?? '0') ?? 0;
    final pending = double.tryParse(row['pending_amount']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(row['paid_amount']?.toString() ?? '0') ?? 0;
    final rejected = double.tryParse(row['rejected_amount']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar, Name, Department & Category Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept${branch.isNotEmpty ? ' • $branch' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Hero Highlight Box: Total Claimed vs Approved Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey900 : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'TOTAL CLAIMED',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border(context),
                ),
                Column(
                  children: [
                    const Text(
                      'APPROVED AMOUNT',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${approved.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Status Breakdown Chips
          Row(
            children: [
              _buildMiniStatusBadge('Paid: \$${paid.toStringAsFixed(0)}', '$claims claims', const Color(0xFF3B82F6)),
              if (pending > 0) ...[
                const SizedBox(width: 6),
                _buildMiniStatusBadge('Pending', '\$${pending.toStringAsFixed(0)}', const Color(0xFFF59E0B)),
              ],
              if (rejected > 0) ...[
                const SizedBox(width: 6),
                _buildMiniStatusBadge('Rejected', '\$${rejected.toStringAsFixed(0)}', const Color(0xFFEF4444)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> row, bool isDark) {
    final name = row['full_name']?.toString() ?? 'Employee';
    final code = row['emp_code']?.toString() ?? '-';
    final dept = row['department']?.toString() ?? '-';
    final branch = row['branch']?.toString() ?? '-';
    final leaveType = row['leave_type']?.toString() ?? 'Leave';
    final isPaid =
        row['is_paid'] == 1 || row['is_paid'] == true || row['is_paid'] == '1';

    final allocated =
        double.tryParse(row['allocated_days']?.toString() ?? '0') ?? 0;
    final used = double.tryParse(row['used_days']?.toString() ?? '0') ?? 0;
    final carried =
        double.tryParse(row['carried_forward']?.toString() ?? '0') ?? 0;
    final remaining =
        double.tryParse(row['remaining_days']?.toString() ?? '0') ?? 0;
    final pending =
        int.tryParse(row['pending_requests']?.toString() ?? '0') ?? 0;

    final totalAvailable = allocated + carried;
    final usagePercent = totalAvailable > 0
        ? ((used / totalAvailable) * 100).clamp(0, 100)
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: ClipOval(
                  child:
                      row['photo_url'] != null &&
                          row['photo_url'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: row['photo_url'].toString(),
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$code • $dept • $branch',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'UNPAID',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leaveType,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$pending Pending',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                'Allocated',
                '${allocated.toStringAsFixed(0)}d',
                AppColors.textPrimary(context),
              ),
              _buildMiniStat(
                'Carried',
                '+${carried.toStringAsFixed(0)}d',
                const Color(0xFF3B82F6),
              ),
              _buildMiniStat(
                'Used',
                '${used.toStringAsFixed(0)}d',
                const Color(0xFFF59E0B),
              ),
              _buildMiniStat(
                'Remaining',
                '${remaining.toStringAsFixed(0)}d',
                const Color(0xFF10B981),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (usagePercent.toDouble()) / 100.0,
              minHeight: 4.5,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercent >= 85
                    ? const Color(0xFFEF4444)
                    : usagePercent >= 50
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.grey500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Summary Reports',
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
            // Summary type grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.15,
              children: _summaryTypes.map((t) {
                final isSelected = _selectedType == t['key'];
                final color = t['color'] as Color;
                return InkWell(
                  onTap: () => _loadSummary(t['key'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(25)
                          : AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border(context),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            t['icon'] as IconData,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? color
                                      : AppColors.textPrimary(context),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isSelected
                                      ? color.withAlpha(200)
                                      : AppColors.grey500,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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

            // Data view
            if (!_isLoading && _selectedType != null && _data.isNotEmpty) ...[
              if (_selectedType == 'attendance')
                _buildAttendanceSummaryView(isDark)
              else if (_selectedType == 'leave')
                _buildLeaveSummaryView(isDark)
              else if (_selectedType == 'overtime')
                _buildOvertimeSummaryView(isDark)
              else if (_selectedType == 'payroll')
                _buildPayrollSummaryView(isDark)
              else if (_selectedType == 'expense')
                _buildExpenseSummaryView(isDark)
              else if (_selectedType == 'performance')
                _buildPerformanceSummaryView(isDark)
              else if (_selectedType == 'recruitment')
                _buildRecruitmentSummaryView(isDark)
              else if (_selectedType == 'training')
                _buildTrainingSummaryView(isDark)
              else ...[
                // Search bar for other types
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Horizontal scrollable table for generic types
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
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
            ],

            // Empty state
            if (!_isLoading && _selectedType != null && _data.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      SizedBox(height: 12),
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assessment_rounded,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      SizedBox(height: 12),
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
