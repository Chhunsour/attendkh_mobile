import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/providers/overtime_providers.dart';
import 'package:attendkh/providers/auth_provider.dart';
import 'package:attendkh/services/overtime_repository.dart';
import 'package:attendkh/models/overtime_request.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/components/custom_date_picker.dart';
import 'package:attendkh/components/custom_time_picker.dart';
import 'package:attendkh/services/network/exceptions.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class RequestOvertimeScreen extends ConsumerStatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  ConsumerState<RequestOvertimeScreen> createState() =>
      _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends ConsumerState<RequestOvertimeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  bool _isLoadingShift = false;
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;

  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchShiftForSelectedDate();
    });
  }

  Future<void> _fetchShiftForSelectedDate() async {
    setState(() => _isLoadingShift = true);
    try {
      final repo = ref.read(overtimeRepositoryProvider);
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final data = await repo.getShiftForDate(
        dateFormatter.format(_selectedDate),
      );

      if (data['is_working'] == true &&
          data['start_time'] != null &&
          data['end_time'] != null) {
        final startParts = (data['start_time'] as String).split(':');
        final endParts = (data['end_time'] as String).split(':');
        setState(() {
          _shiftStart = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]),
          );
          _shiftEnd = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]),
          );
        });
      } else {
        setState(() {
          _shiftStart = null;
          _shiftEnd = null;
        });
      }
    } catch (_) {
      // Ignore shift error
    } finally {
      if (mounted) setState(() => _isLoadingShift = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final date = await showCustomDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _fetchShiftForSelectedDate();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    HapticFeedback.lightImpact();
    final time = await showCustomTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      disabledStart: _shiftStart,
      disabledEnd: _shiftEnd,
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  double get _calculatedOtHours {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return 0;
    return diff / 60.0;
  }

  Future<void> _submitRequest(AppLocalizations l10n) async {
    HapticFeedback.lightImpact();
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fieldRequired),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noEmployeeProfileFound),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(overtimeRepositoryProvider);
      final dateFormatter = DateFormat('yyyy-MM-dd');

      final startStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      await repo.submitOvertimeRequest(
        date: dateFormatter.format(_selectedDate),
        startTime: startStr,
        endTime: endStr,
        reason: reason,
      );

      ref.invalidate(overtimeRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.otSubmittedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _reasonController.clear();
        _tabController.animateTo(1); // Switch to history tab
      }
    } catch (e) {
      String msg = l10n.failedToSubmitRequest;
      if (e is AppException) {
        msg = e.message;
      } else {
        msg = e.toString().replaceAll('Exception: ', '');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $msg'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(overtimeRequestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // ── Gradient Hero Header ──
            _buildHeroHeader(context, isDark),

            // ── Tab Bar Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Request Form
                  _buildRequestForm(context, l10n, isDark),

                  // TAB 2: History List
                  _buildHistoryList(context, requestsAsync, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient Hero Slab matching Dashboard & Leave Page ──
  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient rings
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Row
                Row(
                  children: [
                    _heroIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.overtimeManagement,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.overtimeManagementSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Glass Segmented Tab Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.82),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: -0.1,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    tabs: [
                      Tab(text: l10n.requestOT),
                      Tab(text: l10n.myHistory),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  // ── Tab 1: Request Overtime Form ──
  Widget _buildRequestForm(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (_isSubmitting) {
      return LoadingIndicator(message: l10n.submittingRequest);
    }

    final hours = _calculatedOtHours;

    final Color cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);
    final Color iconBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEFF6FF);
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Shift Policy Banner (Executive Squircle Card) ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                  blurRadius: 10,
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
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                          : const Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 19,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overtime Calculator Policy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_isLoadingShift)
                        Text(
                          'Checking assigned schedule...',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                        )
                      else if (_shiftStart != null && _shiftEnd != null)
                        Text(
                          'Regular Shift: ${_shiftStart!.format(context)} - ${_shiftEnd!.format(context)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : AppColors.primary,
                          ),
                        )
                      else
                        Text(
                          'No scheduled shift (Day off or flexible)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Date Picker Card ──
          Text(
            'Date of Overtime',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.grey300 : AppColors.grey800,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                            : const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: iconColor,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to change date',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Start Time & End Time Pickers (Side by Side) ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.startTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.grey300 : AppColors.grey800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickTime(true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.02,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: iconColor,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _startTime.format(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.grey900,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.endTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.grey300 : AppColors.grey800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickTime(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.02,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_filled_rounded,
                                color: iconColor,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _endTime.format(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.grey900,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Estimated OT Duration Badge ──
          if (hours > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Overtime: ${hours.toStringAsFixed(1)} hours',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Reason Field ──
          Text(
            'Reason & Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.grey300 : AppColors.grey800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe task objectives and why overtime is required...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 26),

          // ── Submit Button ──
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _submitRequest(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.submitOTRequest,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Overtime History List ──
  Widget _buildHistoryList(
    BuildContext context,
    AsyncValue<List<OvertimeRequest>> requestsAsync,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return requestsAsync.when(
      data: (requests) {
        final allCount = requests.length;
        final pendingCount =
            requests.where((r) => r.status.toLowerCase() == 'pending').length;
        final approvedCount =
            requests.where((r) => r.status.toLowerCase() == 'approved').length;
        final rejectedCount =
            requests.where((r) => r.status.toLowerCase() == 'rejected').length;

        final filtered = requests.where((r) {
          if (_statusFilter == 'all') return true;
          return r.status.toLowerCase() == _statusFilter.toLowerCase();
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(overtimeRequestsProvider),
          color: AppColors.primary,
          child: Column(
            children: [
              // Filter Chips Strip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildSeniorFilterChip(l10n.all, 'all', allCount, isDark),
                      const SizedBox(width: 8),
                      _buildSeniorFilterChip(
                        l10n.pending,
                        'pending',
                        pendingCount,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSeniorFilterChip(
                        l10n.approved,
                        'approved',
                        approvedCount,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSeniorFilterChip(
                        l10n.rejected,
                        'rejected',
                        rejectedCount,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Request Cards
              Expanded(
                child: filtered.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Container(
                          height: 380,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF242424)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timer_off_outlined,
                                  size: 28,
                                  color: isDark
                                      ? AppColors.grey500
                                      : AppColors.grey400,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noOtRequests,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) =>
                            _buildHistoryCard(filtered[i], isDark),
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(
              'Failed to load overtime history: $err',
              style: const TextStyle(color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeniorFilterChip(
    String label,
    String value,
    int count,
    bool isDark,
  ) {
    final isSelected = _statusFilter == value;

    final Color chipBg = isSelected
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF242424) : Colors.white);

    final Color chipBorder = isSelected
        ? (isDark ? const Color(0xFF3B82F6) : AppColors.primary)
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0));

    final Color chipTextColor = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    final Color countBg = isSelected
        ? (isDark
            ? const Color(0xFF2563EB).withValues(alpha: 0.30)
            : const Color(0xFFDBEAFE))
        : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF1F5F9));

    final Color countTextColor = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : AppColors.primary)
        : (isDark ? AppColors.grey400 : AppColors.grey600);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _statusFilter = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipBorder,
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.20 : 0.08,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: chipTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: countBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: countTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(OvertimeRequest req, bool isDark) {
    Color statusColor;
    switch (req.status.toLowerCase()) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        break;
      case 'pending':
      default:
        statusColor = AppColors.warning;
    }

    final Color cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);
    final Color iconBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEFF6FF);
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                            : const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.date,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${req.startTime} - ${req.endTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.grey400
                              : AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          if (req.reason != null && req.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      req.reason!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.grey300 : AppColors.grey700,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
