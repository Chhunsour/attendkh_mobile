import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> with SingleTickerProviderStateMixin {
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

  void _openAddManualModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualAttendanceModal(onSaved: () {
        ref.invalidate(allAttendanceLogsProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.attendanceLogsTitle,
                  style: const TextStyle(
                    color: AppColors.grey800,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Text(
                  l10n.attendanceLogsSubtitle,
                  style: const TextStyle(
                    color: AppColors.grey400,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Manual Attendance',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.grey800),
            onPressed: () => _openAddManualModal(context),
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l10n.tabDailyLogs),
            Tab(text: l10n.tabCorrections),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyLogsTab(),
          _CorrectionsTab(),
        ],
      ),
    );
  }
}

class _DailyLogsTab extends ConsumerStatefulWidget {
  const _DailyLogsTab();

  @override
  ConsumerState<_DailyLogsTab> createState() => _DailyLogsTabState();
}

class _DailyLogsTabState extends ConsumerState<_DailyLogsTab> {
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(allAttendanceLogsProvider);
    final l10n = AppLocalizations.of(context)!;

    return logsAsync.when(
      data: (items) {
        // Calculate statistics
        int total = items.length;
        int present = items.where((i) => i.status == 'present').length;
        int lateCount = items.where((i) => i.status == 'late').length;
        int absent = items.where((i) => i.status == 'absent').length;
        int onLeave = items.where((i) => i.status == 'on_leave' || i.status == 'leave').length;

        // Filter items
        final filteredItems = items.where((item) {
          final matchesSearch = item.employeeName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _selectedStatus == 'all' || item.status == _selectedStatus;
          return matchesSearch && matchesStatus;
        }).toList();

        return Column(
          children: [
            // Stats Row
            Container(
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatChip('Total', '$total', AppColors.primary),
                    const SizedBox(width: 8),
                    _buildStatChip('Present', '$present', AppColors.success),
                    const SizedBox(width: 8),
                    _buildStatChip('Late', '$lateCount', AppColors.warning),
                    const SizedBox(width: 8),
                    _buildStatChip('Absent', '$absent', AppColors.danger),
                    const SizedBox(width: 8),
                    _buildStatChip('On Leave', '$onLeave', Colors.purple),
                  ],
                ),
              ),
            ),

            // Search & Filter Chips Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surfaceLight,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search employee name…',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.grey500),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Statuses'),
                        _buildFilterChip('present', 'Present'),
                        _buildFilterChip('late', 'Late'),
                        _buildFilterChip('absent', 'Absent'),
                        _buildFilterChip('on_leave', 'On Leave'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.grey200),

            // List View
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(l10n.noAttendanceRecords, style: const TextStyle(color: AppColors.grey400)),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(allAttendanceLogsProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = filteredItems[i];
                          return _buildAttendanceCard(context, ref, c, l10n);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => LoadingIndicator(message: l10n.loadingLogs),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(allAttendanceLogsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.grey700)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.backgroundLight,
        onSelected: (_) => setState(() => _selectedStatus = key),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, WidgetRef ref, AdminAttendanceRecord c, AppLocalizations l10n) {
    final statusColor = c.status == 'present'
        ? AppColors.success
        : c.status == 'late' || c.status == 'early_leave'
            ? AppColors.warning
            : AppColors.danger;

    final hasUnapprovedEarlyIn =
        (c.earlyClockInMinutes ?? 0) > 0 && (c.approvedPreShiftOtMinutes ?? 0) == 0 && c.canApprovePreShiftOt;

    return InkWell(
      onTap: () => _showRecordDetailsSheet(context, ref, c),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(formatDate(c.date), style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.status.isEmpty ? 'Unknown' : (c.status[0].toUpperCase() + c.status.substring(1).replaceAll('_', ' ')),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),

            if (c.clockIn != null || c.clockOut != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (c.clockIn != null)
                    Text('${l10n.inTime}: ${formatTime(c.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                  if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                  if (c.clockOut != null)
                    Text('${l10n.outTime}: ${formatTime(c.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                ],
              ),
            ],

            if ((c.lateMinutes ?? 0) > 0) ...[
              const SizedBox(height: 4),
              Text('Late: ${c.lateMinutes} mins', style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ],

            if ((c.earlyClockInMinutes ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '${l10n.earlyIn}: ${c.earlyClockInMinutes! ~/ 60}h ${c.earlyClockInMinutes! % 60}m',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if ((c.approvedPreShiftOtMinutes ?? 0) > 0)
                    Text(
                      '${l10n.approved}: ${c.approvedPreShiftOtMinutes! ~/ 60}h ${c.approvedPreShiftOtMinutes! % 60}m',
                      style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],

            if (hasUnapprovedEarlyIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleApproveOt(context, ref, c.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.approvePreShiftOT, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecordDetailsSheet(BuildContext context, WidgetRef ref, AdminAttendanceRecord c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.employeeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Text('Date: ${c.date}', style: const TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 16),
            if (c.clockInPhoto != null) ...[
              const Text('Clock-In Photo:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: '${DioClient.storageUrl}/${c.clockInPhoto!.startsWith('/') ? c.clockInPhoto!.substring(1) : c.clockInPhoto!}',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 40, color: AppColors.grey400),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              Text('Notes: ${c.notes}', style: const TextStyle(color: AppColors.grey700)),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteRecord(context, ref, c.id);
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(adminOpsRepositoryProvider).deleteAttendance(id);
      ref.invalidate(allAttendanceLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance record deleted.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _handleApproveOt(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminOpsRepositoryProvider).approveOvertime(id);
      ref.invalidate(allAttendanceLogsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.preShiftOtApprovedSuccess), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failedMessage(e.toString())), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _CorrectionsTab extends ConsumerWidget {
  const _CorrectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final l10n = AppLocalizations.of(context)!;

    return correctionsAsync.when(
      data: (items) => items.isEmpty
          ? Center(child: Text(l10n.noPendingCorrections, style: const TextStyle(color: AppColors.grey400)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = items[i];
                final statusColor = c.status == 'approved'
                    ? AppColors.success
                    : c.status == 'rejected'
                        ? AppColors.danger
                        : AppColors.warning;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.access_time, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(formatDate(c.date), style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.status.isEmpty ? 'Unknown' : (c.status[0].toUpperCase() + c.status.substring(1)),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      if (c.clockIn != null || c.clockOut != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (c.clockIn != null) Text('${l10n.inTime}: ${formatTime(c.clockIn)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                            if (c.clockIn != null && c.clockOut != null) const SizedBox(width: 16),
                            if (c.clockOut != null) Text('${l10n.outTime}: ${formatTime(c.clockOut)}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                          ],
                        ),
                      ],
                      if (c.reason != null && c.reason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                          child: Text('${l10n.reason}: ${c.reason}', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                        ),
                      ],
                      if (c.status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleAction(context, ref, c.id, false),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                child: Text(l10n.reject),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleAction(context, ref, c.id, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: Text(l10n.approve),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      loading: () => LoadingIndicator(message: l10n.loadingLogs),
      error: (e, _) => Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(attendanceCorrectionsProvider),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, int id, bool approve) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (approve) {
        await ref.read(adminOpsRepositoryProvider).approveCorrection(id);
      } else {
        await ref.read(adminOpsRepositoryProvider).rejectCorrection(id);
      }
      ref.invalidate(attendanceCorrectionsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? l10n.correctionApprovedSuccess : l10n.correctionRejectedSuccess),
          backgroundColor: approve ? AppColors.success : AppColors.danger,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.failedMessage(e.toString())),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }
}

class _ManualAttendanceModal extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _ManualAttendanceModal({required this.onSaved});

  @override
  ConsumerState<_ManualAttendanceModal> createState() => _ManualAttendanceModalState();
}

class _ManualAttendanceModalState extends ConsumerState<_ManualAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _clockInController = TextEditingController();
  final _clockOutController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'present';
  bool _isSaving = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _dateController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      await repo.addManualAttendance({
        'employee_id': _employeeIdController.text.trim(),
        'date': _dateController.text.trim(),
        'clock_in': _clockInController.text.trim().isEmpty ? null : _clockInController.text.trim(),
        'clock_out': _clockOutController.text.trim().isEmpty ? null : _clockOutController.text.trim(),
        'status': _status,
        'notes': _notesController.text.trim(),
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual attendance record added.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Manual Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Employee ID', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter employee ID' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter date' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clockInController,
                decoration: const InputDecoration(labelText: 'Clock In (YYYY-MM-DD HH:MM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clockOutController,
                decoration: const InputDecoration(labelText: 'Clock Out (YYYY-MM-DD HH:MM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'present', child: Text('Present')),
                  DropdownMenuItem(value: 'late', child: Text('Late')),
                  DropdownMenuItem(value: 'absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Record', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}