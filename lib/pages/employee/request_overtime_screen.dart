import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/overtime_providers.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/services/overtime_repository.dart';
import 'package:mpg_hr_mobile_app/models/overtime_request.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/components/custom_time_picker.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class RequestOvertimeScreen extends ConsumerStatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  ConsumerState<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends ConsumerState<RequestOvertimeScreen> with SingleTickerProviderStateMixin {
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
      final data = await repo.getShiftForDate(dateFormatter.format(_selectedDate));

      if (data['is_working'] == true && data['start_time'] != null && data['end_time'] != null) {
        final startParts = (data['start_time'] as String).split(':');
        final endParts = (data['end_time'] as String).split(':');
        setState(() {
          _shiftStart = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
          _shiftEnd = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
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
        const SnackBar(
          content: Text('No employee profile found'),
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

      final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      await repo.submitOvertimeRequest(
        date: dateFormatter.format(_selectedDate),
        startTime: startStr,
        endTime: endStr,
        reason: reason,
      );

      ref.invalidate(overtimeRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Overtime request submitted successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _reasonController.clear();
        _tabController.animateTo(1); // Switch to history tab
      }
    } catch (e) {
      String msg = 'Failed to submit request';
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

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Overtime Management',
          style: TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Request OT'),
            Tab(text: 'My History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Request OT Form ──
          _buildRequestForm(l10n),

          // ── TAB 2: OT History List ──
          _buildHistoryList(requestsAsync),
        ],
      ),
    );
  }

  Widget _buildRequestForm(AppLocalizations l10n) {
    if (_isSubmitting) {
      return LoadingIndicator(message: 'Submitting request...');
    }

    final hours = _calculatedOtHours;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Shift Context Banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shift Schedule',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_isLoadingShift)
                        const Text(
                          'Checking assigned schedule...',
                          style: TextStyle(fontSize: 13, color: AppColors.grey700),
                        )
                      else if (_shiftStart != null && _shiftEnd != null)
                        Text(
                          'Regular Shift: ${_shiftStart!.format(context)} - ${_shiftEnd!.format(context)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        )
                      else
                        const Text(
                          'No scheduled shift (Day off or flexible)',
                          style: TextStyle(fontSize: 13, color: AppColors.grey700, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Date Selector ──
          const Text(
            'Date of Overtime',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
                        ),
                        const SizedBox(height: 2),
                        const Text('Tap to change date', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppColors.grey400),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Time Pickers ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Time',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickTime(true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _startTime.format(context),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
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
                    const Text(
                      'End Time',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickTime(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: Color(0xFF8B5CF6), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _endTime.format(context),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated Overtime: ${hours.toStringAsFixed(1)} hours',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Reason Field ──
          const Text(
            'Reason & Description',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.grey900),
            decoration: InputDecoration(
              hintText: 'Describe task objectives and why overtime is required...',
              hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 28),

          // ── Submit Button ──
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _submitRequest(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Submit Overtime Request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(AsyncValue<List<OvertimeRequest>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', requests.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending', requests.where((r) => r.status == 'pending').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved', 'approved', requests.where((r) => r.status == 'approved').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected', requests.where((r) => r.status == 'rejected').length),
                  ],
                ),
              ),

              // Request Cards
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_off_outlined, size: 48, color: AppColors.grey300),
                            const SizedBox(height: 12),
                            const Text(
                              'No overtime requests found',
                              style: TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _buildHistoryCard(filtered[i]),
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator(message: 'Loading history...')),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text('Failed to load overtime requests: $e', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(overtimeRequestsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(OvertimeRequest req) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Color(0xFF8B5CF6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.date,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${req.startTime} - ${req.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
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
          if (req.reason != null && req.reason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                req.reason!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.grey700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
