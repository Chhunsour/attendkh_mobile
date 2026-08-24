import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/models/monthly_attendance_model.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class MonthlySummaryTab extends ConsumerStatefulWidget {
  const MonthlySummaryTab({super.key});

  @override
  ConsumerState<MonthlySummaryTab> createState() => _MonthlySummaryTabState();
}

class _MonthlySummaryTabState extends ConsumerState<MonthlySummaryTab> {
  DateTime _currentMonth = DateTime.now();
  int? _selectedDepartmentId;
  String _searchQuery = '';

  String get _monthParam => DateFormat('yyyy-MM').format(_currentMonth);
  String get _monthTitle => DateFormat('MMMM yyyy').format(_currentMonth);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  Future<void> _pickMonthYear() async {
    int year = _currentMonth.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
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
                      year == _currentMonth.year && month == _currentMonth.month;
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
      setState(() => _currentMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final departmentsAsync = ref.watch(departmentsProvider);

    final query = CompanyMonthlyAttendanceQuery(
      month: _monthParam,
      departmentId: _selectedDepartmentId,
    );
    final monthlyDataAsync = ref.watch(companyMonthlyAttendanceProvider(query));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(companyMonthlyAttendanceProvider(query));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── 1. Month Picker Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Month',
                ),
                InkWell(
                  onTap: _pickMonthYear,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _monthTitle,
                          style: TextStyle(
                            fontSize: 15,
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
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Month',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── 2. Filters (Search & Department) ──────────────────────────────
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search employee...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: departmentsAsync.when(
                  data: (depts) {
                    return DropdownButtonFormField<int?>(
                      initialValue: _selectedDepartmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface(context),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                      hint: const Text('All Depts',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Depts',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                        ...depts.map((d) => DropdownMenuItem<int?>(
                              value: d.id,
                              child: Text(d.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedDepartmentId = val),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── 3. Data & Metrics Body ─────────────────────────────────────────
          monthlyDataAsync.when(
            data: (data) {
              final summaries = data.summaryData;
              final daysInMonth = data.daysInMonth;

              // Filter by search query
              final filtered = summaries.where((s) {
                if (_searchQuery.trim().isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                final name = s.employee.fullName.toLowerCase();
                final empId = s.employee.employeeId?.toLowerCase() ?? '';
                final dept = s.employee.department.toLowerCase();
                return name.contains(q) || empId.contains(q) || dept.contains(q);
              }).toList();

              // Calculate overall metrics
              final totalStaff = summaries.length;
              final totalPresent =
                  summaries.fold<int>(0, (sum, s) => sum + s.totals.present);
              final totalLate =
                  summaries.fold<int>(0, (sum, s) => sum + s.totals.late);
              final totalAbsent =
                  summaries.fold<int>(0, (sum, s) => sum + s.totals.absent);
              final totalLeave =
                  summaries.fold<int>(0, (sum, s) => sum + s.totals.onLeave);

              final workingOccurrences =
                  totalPresent + totalAbsent + totalLate + totalLeave;
              final attendanceRate = workingOccurrences > 0
                  ? (((totalPresent + totalLate) / workingOccurrences) * 100)
                      .round()
                  : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Score Banner
                  _buildKpiBanner(
                    context,
                    totalStaff: totalStaff,
                    attendanceRate: attendanceRate,
                    present: totalPresent,
                    late: totalLate,
                    absent: totalAbsent,
                    leave: totalLeave,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // Legend
                  _buildLegendBar(context),

                  const SizedBox(height: 14),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EMPLOYEE ATTENDANCE MATRIX',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      Text(
                        '${filtered.length} staff',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 44, color: AppColors.grey400),
                          SizedBox(height: 8),
                          Text(
                            'No employee attendance found',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((item) => _buildEmployeeMatrixCard(
                          context,
                          item,
                          daysInMonth,
                          isDark,
                        )),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: LoadingIndicator(message: 'Loading monthly attendance...'),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 40, color: AppColors.danger),
                  const SizedBox(height: 8),
                  Text('Failed to load monthly attendance: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(companyMonthlyAttendanceProvider(query)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Executive Score Banner ─────────────────────────────────────────────────
  Widget _buildKpiBanner(
    BuildContext context, {
    required int totalStaff,
    required int attendanceRate,
    required int present,
    required int late,
    required int absent,
    required int leave,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2E23), const Color(0xFF064E3B)]
              : [const Color(0xFF059669), const Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Attendance Rate Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: (attendanceRate.clamp(0, 100)) / 100.0,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    '$attendanceRate%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTHLY ATTENDANCE RATE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attendanceRate >= 90
                          ? 'Excellent Reliability'
                          : attendanceRate >= 75
                              ? 'Moderate Attendance'
                              : 'Attendance Needs Attention',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalStaff staff active in $_monthTitle',
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
          const SizedBox(height: 14),
          // Breakdown Pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Present', '$present', Colors.white),
                _buildStatPill('Late', '$late', const Color(0xFFFBBF24)),
                _buildStatPill('Absent', '$absent', const Color(0xFFF87171)),
                _buildStatPill('Leave', '$leave', const Color(0xFF60A5FA)),
              ],
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
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ── Legend Bar ─────────────────────────────────────────────────────────────
  Widget _buildLegendBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendChip('P', 'Present', const Color(0xFF10B981)),
          _buildLegendChip('L', 'Late', const Color(0xFFF59E0B)),
          _buildLegendChip('A', 'Absent', const Color(0xFFEF4444)),
          _buildLegendChip('H', 'Half Day', const Color(0xFFF97316)),
          _buildLegendChip('V', 'Leave', const Color(0xFF3B82F6)),
          _buildLegendChip('W', 'Weekend', const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String code, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Employee Monthly Card with 1..31 Days Matrix ───────────────────────────
  Widget _buildEmployeeMatrixCard(
    BuildContext context,
    MonthlyAttendanceEmployeeSummary item,
    int daysInMonth,
    bool isDark,
  ) {
    final emp = item.employee;
    final totals = item.totals;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Info & Summary Totals
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.border(context), width: 0.5),
                ),
                child: ClipOval(
                  child: emp.photoUrl != null && emp.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: emp.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
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
                      emp.fullName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${emp.department} • ${emp.branch}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              // Totals summary badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniCountBadge('P: ${totals.present}', const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  _buildMiniCountBadge('L: ${totals.late}', const Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  _buildMiniCountBadge('A: ${totals.absent}', const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 1..31 Horizontal Day Tiles Matrix
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (context, idx) {
                final day = idx + 1;
                final status = item.days[day];
                return _buildDayTile(day, status);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDayTile(int day, String? status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      width: 32,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: statusConfig.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusConfig.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusConfig.dayColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusConfig.code,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: statusConfig.codeColor,
            ),
          ),
        ],
      ),
    );
  }

  _DayTileConfig _getStatusConfig(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return _DayTileConfig(
          code: 'P',
          bg: const Color(0xFF10B981),
          border: const Color(0xFF059669),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'late':
        return _DayTileConfig(
          code: 'L',
          bg: const Color(0xFFF59E0B),
          border: const Color(0xFFD97706),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'absent':
        return _DayTileConfig(
          code: 'A',
          bg: const Color(0xFFEF4444),
          border: const Color(0xFFDC2626),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'half_day':
        return _DayTileConfig(
          code: 'H',
          bg: const Color(0xFFF97316),
          border: const Color(0xFFEA580C),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'on_leave':
        return _DayTileConfig(
          code: 'V',
          bg: const Color(0xFF3B82F6),
          border: const Color(0xFF2563EB),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'holiday':
        return _DayTileConfig(
          code: 'H',
          bg: const Color(0xFF8B5CF6),
          border: const Color(0xFF7C3AED),
          dayColor: Colors.white70,
          codeColor: Colors.white,
        );
      case 'weekend':
        return _DayTileConfig(
          code: 'W',
          bg: const Color(0xFFF3F4F6),
          border: const Color(0xFFE5E7EB),
          dayColor: const Color(0xFF9CA3AF),
          codeColor: const Color(0xFF6B7280),
        );
      default:
        return _DayTileConfig(
          code: '—',
          bg: const Color(0xFFF9FAFB),
          border: const Color(0xFFE5E7EB),
          dayColor: const Color(0xFF9CA3AF),
          codeColor: const Color(0xFF9CA3AF),
        );
    }
  }
}

class _DayTileConfig {
  final String code;
  final Color bg;
  final Color border;
  final Color dayColor;
  final Color codeColor;

  _DayTileConfig({
    required this.code,
    required this.bg,
    required this.border,
    required this.dayColor,
    required this.codeColor,
  });
}
