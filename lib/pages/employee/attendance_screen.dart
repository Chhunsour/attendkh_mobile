import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodayTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ── Today Tab ──────────────────────────────────────────────
class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAttendanceProvider);
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final summaryAsync = ref.watch(attendanceSummaryProvider(currentMonth));

    return todayAsync.when(
      data: (today) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildClockCard(context, ref, today),
            const SizedBox(height: 20),

            // Monthly Summary
            const Text('Monthly Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (summary) => _SummaryGrid(summary: summary),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Today's Log
            const Text('Today\'s Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 12),
            if (today == null)
              _emptyLogCard()
            else ...[
              _LogRow(label: 'Clock In', value: _formatTime(today.clockIn)),
              if (today.clockOut != null) _LogRow(label: 'Clock Out', value: _formatTime(today.clockOut!)),
              if (today.status != null) _LogRow(label: 'Status', value: (today.status ?? '').replaceAll('_', ' ').toUpperCase()),
              if (today.workHours != null) _LogRow(label: 'Work Hours', value: '${today.workHours!.toStringAsFixed(1)}h'),
            ],
          ],
        ),
      ),
      loading: () => const LoadingIndicator(message: 'Loading...'),
      error: (error, _) => _buildError(context, ref, error.toString()),
    );
  }

  Widget _buildClockCard(BuildContext context, WidgetRef ref, TodayAttendance? today) {
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isClockedIn ? [AppColors.success, const Color(0xFF16A34A)] : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: (isClockedIn ? AppColors.success : AppColors.primary).withAlpha(51), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Icon(isClockedIn ? Icons.timer : Icons.access_time, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(today?.date ?? DateFormat('dd MMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          if (isClockedIn) ...[
            Text('Clocked in at ${_formatTime(today!.clockIn!)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            if (today.workHours != null) Text('Working: ${today.workHours!.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ] else if (today?.clockOut != null) ...[
            const Text('Shift completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            if (today!.workHours != null) Text('${today.workHours!.toStringAsFixed(1)} hours today', style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ] else ...[
            const Text('Not clocked in yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isClockedIn ? null : () => _handleClockIn(context, ref),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.login),
                  label: const Text('Clock In', overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isClockedIn ? () => _handleClockOut(context, ref) : null,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.logout),
                  label: const Text('Clock Out', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyLogCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
    child: const Center(child: Text('No records yet — tap Clock In to start', style: TextStyle(color: AppColors.grey400))),
  );

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            const Text('Failed to load attendance', style: TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => ref.invalidate(todayAttendanceProvider), icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _captureAttendanceData(BuildContext context) async {
    try {
      // 1. Get GPS Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled. Please enable them.')));
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied. Cannot clock in/out.')));
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
        return null;
      } 

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // 2. Take Selfie
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (image == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selfie is required to clock in/out.')));
        return null;
      }

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'photoPath': image.path,
      };
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location/camera: $e')));
      return null;
    }
  }

  Future<void> _handleClockIn(BuildContext context, WidgetRef ref) async {
    try {
      final data = await _captureAttendanceData(context);
      if (data == null) return;

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockIn(
        lat: data['lat'],
        lng: data['lng'],
        photoPath: data['photoPath'],
      );
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✅ Clocked in successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  Future<void> _handleClockOut(BuildContext context, WidgetRef ref) async {
    try {
      final data = await _captureAttendanceData(context);
      if (data == null) return;

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockOut(
        lat: data['lat'],
        lng: data['lng'],
        photoPath: data['photoPath'],
      );
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✅ Clocked out successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final parts = timeStr.split(' ');
      final timePart = parts.length > 1 ? parts[1] : parts[0];
      final t = timePart.split(':');
      final hour = int.parse(t[0]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${t[1]} $period';
    } catch (_) {
      return timeStr;
    }
  }
}

// ── History Tab ────────────────────────────────────────────
class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab();

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider(_selectedMonth));

    return Column(
      children: [
        // Month picker
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Expanded(
                child: Text(_monthLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
        ),

        // Correction request button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCorrectionDialog(context),
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Request Correction'),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // History list
        Expanded(
          child: historyAsync.when(
            data: (records) => records.isEmpty
              ? const Center(child: Text('No attendance records this month', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final r = records[i];
                    return _HistoryCard(record: r);
                  },
                ),
            loading: () => const LoadingIndicator(message: 'Loading history...'),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: () => ref.invalidate(attendanceHistoryProvider(_selectedMonth)), icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _monthLabel {
    try {
      final parts = _selectedMonth.split('-');
      final m = int.parse(parts[1]);
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[m - 1]} ${parts[0]}';
    } catch (_) {
      return _selectedMonth;
    }
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]) + delta;
    final newDate = DateTime(year, month);
    setState(() => _selectedMonth = DateFormat('yyyy-MM').format(newDate));
  }

  Future<void> _showCorrectionDialog(BuildContext context) async {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String correctionType = 'missed_clock_in';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Correction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: correctionType,
                decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                items: const [
                  DropdownMenuItem(value: 'missed_clock_in', child: Text('Missed Clock In')),
                  DropdownMenuItem(value: 'missed_clock_out', child: Text('Missed Clock Out')),
                  DropdownMenuItem(value: 'wrong_time', child: Text('Wrong Time')),
                ],
                onChanged: (v) => setDialogState(() => correctionType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Reason', prefixIcon: Icon(Icons.description)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );

    if (result == true && dateCtrl.text.isNotEmpty) {
      try {
        final repo = ref.read(attendanceRepositoryProvider);
        await repo.requestCorrection(
          date: dateCtrl.text.trim(),
          type: correctionType,
          reason: reasonCtrl.text.trim().isEmpty ? 'No reason provided' : reasonCtrl.text.trim(),
        );
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Correction request submitted'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

// ── Shared Widgets ─────────────────────────────────────────
class _SummaryGrid extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(label: 'Present', value: '${summary.present}', color: AppColors.success),
        const SizedBox(width: 8),
        _SummaryCard(label: 'Absent', value: '${summary.absent}', color: AppColors.danger),
        const SizedBox(width: 8),
        _SummaryCard(label: 'Late', value: '${summary.late}', color: AppColors.warning),
        const SizedBox(width: 8),
        _SummaryCard(label: 'Half-Day', value: '${summary.halfDay}', color: AppColors.info),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(40))),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final String label;
  final String? value;
  const _LogRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey200)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
            Text(value ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TodayAttendance record;
  const _HistoryCard({required this.record});

  Color get _statusColor {
    switch (record.status) {
      case 'present': return AppColors.success;
      case 'absent': return AppColors.danger;
      case 'late': return AppColors.warning;
      case 'half_day': return AppColors.info;
      default: return AppColors.grey400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = record.date ?? '';
    String displayDate = dateStr;
    try {
      final dt = DateTime.parse(dateStr);
      displayDate = DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey200)),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.access_time, color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'In: ${_fmt(record.clockIn)}  |  Out: ${_fmt(record.clockOut)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
                if (record.workHours != null)
                  Text('${record.workHours!.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withAlpha(26), borderRadius: BorderRadius.circular(5)),
            child: Text(
              (record.status ?? 'unknown').replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String? s) {
    if (s == null || s.isEmpty) return '—';
    try {
      final parts = s.split(' ');
      final timePart = parts.length > 1 ? parts[1] : parts[0];
      final t = timePart.split(':');
      final h = int.parse(t[0]);
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${t[1]} $period';
    } catch (_) { return s; }
  }
}