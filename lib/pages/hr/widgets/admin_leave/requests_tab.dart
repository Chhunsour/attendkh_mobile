import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_leave/leave_shared_widgets.dart';

class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(allLeaveRequestsProvider);

    final filters = [
      ('all', l10n.filterAll),
      ('pending', l10n.filterPending),
      ('approved', l10n.filterApproved),
      ('rejected', l10n.filterRejected),
    ];

    return Stack(
      children: [
        Column(
          children: [
            // ── Filter chips ───────────────────────────────────────────────
            Container(
              color: AppColors.surfaceLight,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isActive = _filter == f.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            f.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.grey600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.grey100),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: requestsAsync.when(
                data: (items) {
                  final filtered = _filter == 'all'
                      ? items
                      : items.where((r) => r.status == _filter).toList();
                  if (filtered.isEmpty) {
                    return LeaveEmptyPlaceholder(
                      icon: Icons.inbox_rounded,
                      message: _filter == 'all'
                          ? l10n.noLeaveRequests
                          : l10n.noRequestsByFilter(
                              filters.firstWhere((f) => f.$1 == _filter).$2,
                            ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestCard(request: filtered[i]),
                    ),
                  );
                },
                loading: () => LoadingIndicator(message: l10n.loadingLogs),
                error: (e, _) => LeaveErrorRetry(
                  onRetry: () => ref.invalidate(allLeaveRequestsProvider),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: LeaveGradientFAB(
            label: l10n.newRequest,
            icon: Icons.add_rounded,
            onPressed: () => _showAddRequestSheet(context),
          ),
        ),
      ],
    );
  }

  void _showAddRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => _AddRequestSheet(
          scrollController: ctrl,
          onSaved: () => ref.invalidate(allLeaveRequestsProvider),
        ),
      ),
    );
  }
}

class _AddRequestSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onSaved;
  const _AddRequestSheet({
    required this.scrollController,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddRequestSheet> createState() => _AddRequestSheetState();
}

class _AddRequestSheetState extends ConsumerState<_AddRequestSheet> {
  final _reasonCtrl = TextEditingController();
  String _startDate = DateTime.now().toString().split(' ')[0];
  String _endDate = DateTime.now().toString().split(' ')[0];
  bool _halfDay = false;
  String _halfDayPeriod = 'morning';
  bool _loading = false;

  int? _selectedEmpId;
  int? _selectedTypeId;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employeesAsync = ref.watch(allEmployeesProvider);
    final leaveTypesAsync = ref.watch(leaveTypesProvider);

    return Material(
      color: AppColors.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.note_add_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.newLeaveRequest,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        l10n.submitLeaveApp,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatefulBuilder(
                builder: (ctx, setSt) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee picker
                    Text(
                      l10n.employeeRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    employeesAsync.when(
                      data: (emps) => DropdownButtonFormField<int>(
                        initialValue: _selectedEmpId,
                        decoration: _dropDec(),
                        hint: Text(
                          l10n.selectEmployee,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                        ),
                        items: emps
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  e.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setSt(() => _selectedEmpId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Failed to load employees'),
                    ),
                    const SizedBox(height: 14),

                    // Leave type picker
                    Text(
                      l10n.leaveTypeRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    leaveTypesAsync.when(
                      data: (types) => DropdownButtonFormField<int>(
                        initialValue: _selectedTypeId,
                        decoration: _dropDec(),
                        hint: Text(
                          l10n.selectLeaveType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                        ),
                        items: types
                            .where((t) => t.isActive)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setSt(() => _selectedTypeId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Failed to load leave types'),
                    ),
                    const SizedBox(height: 14),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.startDateRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _startDate,
                                decoration: _dropDec(),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (v) => setSt(() => _startDate = v),
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
                                l10n.endDateRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _endDate,
                                decoration: _dropDec(),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (v) => setSt(() => _endDate = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Half day
                    Row(
                      children: [
                        Checkbox(
                          value: _halfDay,
                          onChanged: (v) => setSt(() => _halfDay = v ?? false),
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          l10n.halfDay,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        if (_halfDay) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _halfDayPeriod,
                              decoration: _dropDec(),
                              items: [
                                DropdownMenuItem(
                                  value: 'morning',
                                  child: Text(
                                    l10n.morning,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'afternoon',
                                  child: Text(
                                    l10n.afternoon,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setSt(() => _halfDayPeriod = v!),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Reason
                    Text(
                      l10n.reasonRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: _dropDec().copyWith(
                        hintText: l10n.reasonForLeaveHint,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            (_loading ||
                                _selectedEmpId == null ||
                                _selectedTypeId == null ||
                                _reasonCtrl.text.trim().isEmpty)
                            ? null
                            : () async {
                                setSt(() => _loading = true);
                                try {
                                  await ref
                                      .read(adminOpsRepositoryProvider)
                                      .createLeaveRequest(
                                        employeeId: _selectedEmpId!,
                                        leaveTypeId: _selectedTypeId!,
                                        startDate: _startDate,
                                        endDate: _endDate,
                                        reason: _reasonCtrl.text.trim(),
                                        halfDay: _halfDay,
                                        halfDayPeriod: _halfDay
                                            ? _halfDayPeriod
                                            : null,
                                      );
                                  widget.onSaved();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.requestSubmitted),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                } finally {
                                  setSt(() => _loading = false);
                                }
                              },
                        child: _loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.textPrimary(context),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.submitRequest,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDec([BuildContext? context]) => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: context != null ? (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDarkElevated : AppColors.grey50) : AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}

class _RequestCard extends ConsumerWidget {
  final AdminLeaveRequestData request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sc = leaveStatusColor(request.status);
    final tc = leaveTypeColor(request.leaveTypeColor);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary(context).withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: avatar + name + days + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar / Photo
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(21),
                            image:
                                (request.employeePhoto != null &&
                                    request.employeePhoto!.isNotEmpty)
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      request.employeePhoto!.startsWith('http')
                                          ? request.employeePhoto!
                                          : '${DioClient.storageUrl}/${request.employeePhoto!.startsWith('/') ? request.employeePhoto!.substring(1) : request.employeePhoto!}',
                                      maxWidth: 120,
                                      maxHeight: 120,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              (request.employeePhoto == null ||
                                  request.employeePhoto!.isEmpty)
                              ? Center(
                                  child: Text(
                                    request.employeeName.isNotEmpty
                                        ? request.employeeName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: tc,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.employeeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Row(
                                children: [
                                  if (request.employeeCode != null &&
                                      request.employeeCode!.isNotEmpty)
                                    Text(
                                      request.employeeCode!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey400,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  if (request.employeePosition != null &&
                                      request.employeePosition!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        request.employeePosition!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: tc,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    request.leaveTypeName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (request.halfDay) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.halfDayLabel,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${request.days}${AppLocalizations.of(context)!.daysShort}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: sc,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: sc.withAlpha(18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _capitalizeStatus(context, request.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: sc,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Date range
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatDateRange(request.startDate, request.endDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),

                    // Reason
                    if (request.reason != null &&
                        request.reason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        request.reason!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Approve / Reject
                    if (request.status == 'pending') ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.grey100),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _action(context, ref, request, 'reject'),
                              icon: const Icon(Icons.close_rounded, size: 15),
                              label: Text(AppLocalizations.of(context)!.reject),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(
                                  color: AppColors.danger,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _action(context, ref, request, 'approve'),
                              icon: const Icon(Icons.check_rounded, size: 15),
                              label: Text(
                                AppLocalizations.of(context)!.approve,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeStatus(BuildContext context, String status) {
    if (status.isEmpty) return status;
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.filterPending;
      case 'approved':
        return l10n.filterApproved;
      case 'rejected':
        return l10n.filterRejected;
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    AdminLeaveRequestData request,
    String action,
  ) async {
    final isApprove = action == 'approve';
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApprove ? AppColors.success : AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isApprove ? 'Approve Leave Request' : 'Reject Leave Request',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Approve leave request for ${request.employeeName.isNotEmpty ? request.employeeName : "employee"}?'
                  : 'Reject leave request for ${request.employeeName.isNotEmpty ? request.employeeName : "employee"}?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isApprove
                    ? 'Approver Notes (Optional)'
                    : 'Rejection Reason (Optional)',
                hintText: isApprove
                    ? 'e.g. Approved, please hand over tasks'
                    : 'e.g. Insufficient leave notice provided',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(adminOpsRepositoryProvider);
        final notes = notesCtrl.text.trim();
        if (isApprove) {
          await repo.approveLeaveRequest(
            request.id,
            notes: notes.isNotEmpty ? notes : null,
          );
        } else {
          await repo.rejectLeaveRequest(
            request.id,
            reason: notes.isNotEmpty ? notes : null,
          );
        }
        ref.invalidate(allLeaveRequestsProvider);
        ref.invalidate(leaveBalancesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isApprove
                        ? 'Leave request approved.'
                        : 'Leave request rejected.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: isApprove
                  ? AppColors.success
                  : AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
