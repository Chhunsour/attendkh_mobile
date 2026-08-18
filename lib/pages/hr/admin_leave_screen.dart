import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

// ─── Color helpers ─────────────────────────────────────────────────────────
Color _statusColor(String s) {
  switch (s) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.danger;
    case 'cancelled':
      return AppColors.grey400;
    default:
      return AppColors.warning;
  }
}

Color _typeColor(String? hex) {
  if (hex == null) return AppColors.primary;
  try {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.leaveManagementTitle,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(allLeaveRequestsProvider);
              ref.invalidate(leaveTypesProvider);
              ref.invalidate(leaveBalancesProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFEF4444),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFFEF4444),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabRequests),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(l10n.tabBalances),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabTypes),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_RequestsTab(), _LeaveBalancesTab(), _LeaveTypesTab()],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REQUESTS TAB
// ══════════════════════════════════════════════════════════════════════════════
class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab();

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
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
                    return _EmptyPlaceholder(
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
                error: (e, _) => _ErrorRetry(
                  onRetry: () => ref.invalidate(allLeaveRequestsProvider),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: _GradientFAB(
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.grey800,
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey800,
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
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

  InputDecoration _dropDec() => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
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
    final sc = _statusColor(request.status);
    final tc = _typeColor(request.leaveTypeColor);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withAlpha(8),
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
                                    image: NetworkImage(
                                      request.employeePhoto!.startsWith('http')
                                          ? request.employeePhoto!
                                          : '${DioClient.storageUrl}/${request.employeePhoto!.startsWith('/') ? request.employeePhoto!.substring(1) : request.employeePhoto!}',
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.grey800,
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
                                  _action(context, ref, request.id, 'reject'),
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
                                  _action(context, ref, request.id, 'approve'),
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
    int id,
    String action,
  ) async {
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      if (action == 'approve') {
        await repo.approveLeaveRequest(id);
      } else {
        await repo.rejectLeaveRequest(id);
      }
      ref.invalidate(allLeaveRequestsProvider);
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
                Text(AppLocalizations.of(context)!.requestActioned(action)),
              ],
            ),
            backgroundColor: action == 'approve'
                ? AppColors.success
                : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BALANCES TAB
// ══════════════════════════════════════════════════════════════════════════════
class _LeaveBalancesTab extends ConsumerStatefulWidget {
  const _LeaveBalancesTab();

  @override
  ConsumerState<_LeaveBalancesTab> createState() => _LeaveBalancesTabState();
}

class _LeaveBalancesTabState extends ConsumerState<_LeaveBalancesTab> {
  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(leaveBalancesProvider);

    return Stack(
      children: [
        balancesAsync.when(
          data: (items) => items.isEmpty
              ? _EmptyPlaceholder(
                  icon: Icons.account_balance_wallet_rounded,
                  message: AppLocalizations.of(context)!.noLeaveBalances,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BalanceCard(balance: items[i]),
                  ),
                ),
          loading: () => LoadingIndicator(
            message: AppLocalizations.of(context)!.loadingBalances,
          ),
          error: (e, _) =>
              _ErrorRetry(onRetry: () => ref.invalidate(leaveBalancesProvider)),
        ),

        // FAB
        Positioned(
          right: 16,
          bottom: 20,
          child: _GradientFAB(
            label: AppLocalizations.of(context)!.addBalance,
            icon: Icons.add_rounded,
            onPressed: () => _showAddBalanceSheet(context),
          ),
        ),
      ],
    );
  }

  void _showAddBalanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => _AddBalanceSheet(
          scrollController: ctrl,
          onSaved: () => ref.invalidate(leaveBalancesProvider),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final LeaveBalanceData balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining =
        balance.allocatedDays + balance.carriedForward - balance.usedDays;
    final total = balance.allocatedDays > 0 ? balance.allocatedDays : 1;
    final pct = ((remaining / total) * 100).clamp(0, 100).toDouble();
    final barColor = pct > 50
        ? AppColors.success
        : pct > 20
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    balance.employeeAvatar != null &&
                        balance.employeeAvatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          balance.employeeAvatar!.startsWith('http')
                              ? balance.employeeAvatar!
                              : '${DioClient.storageUrl}/${balance.employeeAvatar!.startsWith('/') ? balance.employeeAvatar!.substring(1) : balance.employeeAvatar!}',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              balance.employeeName.isNotEmpty
                                  ? balance.employeeName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          balance.employeeName.isNotEmpty
                              ? balance.employeeName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primary,
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
                      balance.employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.grey800,
                      ),
                    ),
                    Row(
                      children: [
                        if (balance.employeeCode != null &&
                            balance.employeeCode!.isNotEmpty)
                          Text(
                            balance.employeeCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (balance.employeePosition != null &&
                            balance.employeePosition!.isNotEmpty) ...[
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
                              balance.employeePosition!,
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
                    const SizedBox(height: 2),
                    Text(
                      '${balance.leaveTypeName} · ${balance.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              GestureDetector(
                onTap: () => _editBalance(context, ref, balance),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _BalanceStat(
                label: AppLocalizations.of(context)!.allocated,
                value: balance.allocatedDays,
                color: AppColors.primary,
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.used,
                value: balance.usedDays,
                color: AppColors.warning,
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.carried,
                value: balance.carriedForward,
                color: const Color(0xFF8B5CF6),
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.remaining,
                value: remaining,
                color: barColor,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.grey100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  void _editBalance(BuildContext context, WidgetRef ref, LeaveBalanceData b) {
    final allocCtrl = TextEditingController(text: b.allocatedDays.toString());
    final carriedCtrl = TextEditingController(
      text: b.carriedForward.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.editBalanceTitle(b.employeeName),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.grey800,
                ),
              ),
              Text(
                b.leaveTypeName,
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                      controller: allocCtrl,
                      label: AppLocalizations.of(context)!.allocatedDays,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetField(
                      controller: carriedCtrl,
                      label: AppLocalizations.of(context)!.carriedForward,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  onPressed: () async {
                    try {
                      await ref
                          .read(adminOpsRepositoryProvider)
                          .updateLeaveBalance(b.id, {
                            'allocated_days':
                                double.tryParse(allocCtrl.text) ??
                                b.allocatedDays,
                            'carried_forward':
                                double.tryParse(carriedCtrl.text) ??
                                b.carriedForward,
                          });
                      ref.invalidate(leaveBalancesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.balanceUpdated,
                            ),
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
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.saveChanges,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value % 1 == 0
                ? value.toInt().toString()
                : value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBalanceSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onSaved;
  const _AddBalanceSheet({
    required this.scrollController,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddBalanceSheet> createState() => _AddBalanceSheetState();
}

class _AddBalanceSheetState extends ConsumerState<_AddBalanceSheet> {
  final _allocCtrl = TextEditingController(text: '12');
  final _carriedCtrl = TextEditingController(text: '0');
  int _year = DateTime.now().year;
  bool _loading = false;

  @override
  void dispose() {
    _allocCtrl.dispose();
    _carriedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final leaveTypesAsync = ref.watch(leaveTypesProvider);

    int? selectedEmpId;
    int? selectedTypeId;
    bool bulkMode = false;
    final List<int> selectedEmpIds = [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    Icons.account_balance_wallet_rounded,
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
                        AppLocalizations.of(context)!.addLeaveBalance,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.grey800,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.addLeaveBalanceSubtitle,
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
                    // Single / Bulk mode toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSt(() => bulkMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !bulkMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Single Employee',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: !bulkMode
                                        ? AppColors.grey800
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSt(() => bulkMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bulkMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Multiple / All Employees',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: bulkMode
                                        ? AppColors.grey800
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Employee picker
                    if (!bulkMode) ...[
                      Text(
                        AppLocalizations.of(context)!.employeeRequired,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      employeesAsync.when(
                        data: (emps) => DropdownButtonFormField<int>(
                          initialValue: selectedEmpId,
                          decoration: _dropDec(),
                          hint: Text(
                            AppLocalizations.of(context)!.selectEmployee,
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
                          onChanged: (v) => setSt(() => selectedEmpId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Failed to load employees'),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.employeesRequired,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                          employeesAsync.maybeWhen(
                            data: (emps) => GestureDetector(
                              onTap: () => setSt(() {
                                if (selectedEmpIds.length == emps.length) {
                                  selectedEmpIds.clear();
                                } else {
                                  selectedEmpIds
                                    ..clear()
                                    ..addAll(emps.map((e) => e.id));
                                }
                              }),
                              child: Text(
                                emps.isNotEmpty &&
                                        selectedEmpIds.length == emps.length
                                    ? AppLocalizations.of(context)!.deselectAll
                                    : AppLocalizations.of(context)!.selectAll,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      employeesAsync.when(
                        data: (emps) => Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.grey200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: emps.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppColors.grey100,
                            ),
                            itemBuilder: (_, i) {
                              final e = emps[i];
                              final checked = selectedEmpIds.contains(e.id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(
                                  e.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                activeColor: AppColors.primary,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (v) => setSt(() {
                                  if (v == true) {
                                    selectedEmpIds.add(e.id);
                                  } else {
                                    selectedEmpIds.remove(e.id);
                                  }
                                }),
                              );
                            },
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Failed to load employees'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.employeesSelected(selectedEmpIds.length),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Leave type picker
                    Text(
                      AppLocalizations.of(context)!.leaveTypeRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    leaveTypesAsync.when(
                      data: (types) => DropdownButtonFormField<int>(
                        initialValue: selectedTypeId,
                        decoration: _dropDec(),
                        hint: Text(
                          AppLocalizations.of(context)!.selectLeaveType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                        ),
                        items: types
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
                        onChanged: (v) => setSt(() => selectedTypeId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Failed to load leave types'),
                    ),
                    const SizedBox(height: 14),

                    // Year + Allocated row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.yearRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _year.toString(),
                                keyboardType: TextInputType.number,
                                decoration: _dropDec(),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (v) => setSt(
                                  () => _year = int.tryParse(v) ?? _year,
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
                                AppLocalizations.of(
                                  context,
                                )!.allocatedDaysRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _SheetField(
                                controller: _allocCtrl,
                                label: '',
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      AppLocalizations.of(context)!.carriedForward,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SheetField(
                      controller: _carriedCtrl,
                      label: '',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                                selectedTypeId == null ||
                                (!bulkMode && selectedEmpId == null) ||
                                (bulkMode && selectedEmpIds.isEmpty))
                            ? null
                            : () async {
                                setSt(() => _loading = true);
                                try {
                                  final allocatedDays =
                                      double.tryParse(_allocCtrl.text) ?? 12;
                                  final carriedForward =
                                      double.tryParse(_carriedCtrl.text) ?? 0;
                                  if (bulkMode) {
                                    await ref
                                        .read(adminOpsRepositoryProvider)
                                        .bulkAssignLeaveBalance(
                                          employeeIds: selectedEmpIds,
                                          leaveTypeId: selectedTypeId!,
                                          year: _year,
                                          allocatedDays: allocatedDays,
                                          carriedForward: carriedForward,
                                        );
                                  } else {
                                    await ref
                                        .read(adminOpsRepositoryProvider)
                                        .createLeaveBalance(
                                          employeeId: selectedEmpId!,
                                          leaveTypeId: selectedTypeId!,
                                          year: _year,
                                          allocatedDays: allocatedDays,
                                          carriedForward: carriedForward,
                                        );
                                  }
                                  widget.onSaved();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          bulkMode
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.leaveBalanceAssignedMulti(
                                                  selectedEmpIds.length,
                                                )
                                              : AppLocalizations.of(
                                                  context,
                                                )!.leaveBalanceCreated,
                                        ),
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
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                bulkMode
                                    ? AppLocalizations.of(
                                        context,
                                      )!.assignToEmployees
                                    : AppLocalizations.of(context)!.addBalance,
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

  InputDecoration _dropDec() => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// LEAVE TYPES TAB
// ══════════════════════════════════════════════════════════════════════════════
class _LeaveTypesTab extends ConsumerWidget {
  const _LeaveTypesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);

    return Stack(
      children: [
        typesAsync.when(
          data: (items) => items.isEmpty
              ? _EmptyPlaceholder(
                  icon: Icons.label_rounded,
                  message: AppLocalizations.of(context)!.noLeaveTypes,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LeaveTypeCard(
                      type: items[i],
                      onEdit: (t) => _showTypeSheet(context, ref, t),
                    ),
                  ),
                ),
          loading: () => LoadingIndicator(
            message: AppLocalizations.of(context)!.loadingTypes,
          ),
          error: (e, _) =>
              _ErrorRetry(onRetry: () => ref.invalidate(leaveTypesProvider)),
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: _GradientFAB(
            label: AppLocalizations.of(context)!.newType,
            icon: Icons.add_rounded,
            onPressed: () => _showTypeSheet(context, ref),
          ),
        ),
      ],
    );
  }

  void _showTypeSheet(
    BuildContext context,
    WidgetRef ref, [
    LeaveTypeData? type,
  ]) {
    final isEdit = type != null;
    final nameCtrl = TextEditingController(text: type?.name ?? '');
    final daysCtrl = TextEditingController(
      text: (type?.defaultDays ?? 12).toString(),
    );
    final codeCtrl = TextEditingController(text: type?.code ?? '');
    final noticeCtrl = TextEditingController(
      text: (type?.noticePeriodDays ?? 0).toString(),
    );
    final minTenureCtrl = TextEditingController(
      text: type?.minimumTenureDays?.toString() ?? '',
    );
    final maxConsecutiveCtrl = TextEditingController(
      text: type?.maxConsecutiveDays?.toString() ?? '',
    );
    final maxCarryForwardCtrl = TextEditingController(
      text: type?.maxCarryForward?.toString() ?? '',
    );
    final sortOrderCtrl = TextEditingController(
      text: (type?.sortOrder ?? 0).toString(),
    );

    bool isPaid = type?.isPaid ?? true;
    bool carryForward = type?.carryForward ?? false;
    bool requiresDocument = type?.requiresDocument ?? false;
    bool isActive = type?.isActive ?? true;
    bool isProrated = type?.isProrated ?? false;
    bool allowHalfDay = type?.allowHalfDay ?? false;
    String genderSpecific = type?.genderSpecific ?? 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                child: Text(
                  isEdit
                      ? AppLocalizations.of(context)!.editLeaveType
                      : AppLocalizations.of(context)!.addLeaveType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.grey800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StatefulBuilder(
                    builder: (ctx2, setSt) {
                      String selectedColor = type?.color ?? '#f97316';
                      const colors = [
                        '#f97316',
                        '#3b82f6',
                        '#10b981',
                        '#ef4444',
                        '#8b5cf6',
                        '#ec4899',
                        '#14b8a6',
                        '#f59e0b',
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── General Information ──────────────────────────
                          Text(
                            AppLocalizations.of(context)!.generalInfo,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _SheetField(
                                  controller: nameCtrl,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.nameRequired,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 100,
                                child: _SheetField(
                                  controller: codeCtrl,
                                  label: AppLocalizations.of(context)!.code,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SheetField(
                                  controller: daysCtrl,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.daysPerYear,
                                  keyboard:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SheetField(
                                  controller: sortOrderCtrl,
                                  label: AppLocalizations.of(
                                    context,
                                  )!.sortOrder,
                                  keyboard: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.color,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (_, setColor) => Wrap(
                              spacing: 8,
                              children: colors.map((c) {
                                final col = _typeColor(c);
                                final sel = selectedColor == c;
                                return GestureDetector(
                                  onTap: () =>
                                      setColor(() => selectedColor = c),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.grey800
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: sel
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Accrual & Balances ───────────────────────────
                          Text(
                            AppLocalizations.of(context)!.accrualAndBalances,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            value: isProrated,
                            onChanged: (v) =>
                                setSt(() => isProrated = v ?? false),
                            title: Text(
                              AppLocalizations.of(context)!.prorateAccrual,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          CheckboxListTile(
                            value: carryForward,
                            onChanged: (v) =>
                                setSt(() => carryForward = v ?? false),
                            title: Text(
                              AppLocalizations.of(context)!.allowCarryForward,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          if (carryForward) ...[
                            const SizedBox(height: 4),
                            _SheetField(
                              controller: maxCarryForwardCtrl,
                              label: AppLocalizations.of(
                                context,
                              )!.maxCarryForwardDays,
                              keyboard: TextInputType.number,
                            ),
                            const SizedBox(height: 8),
                          ],

                          const SizedBox(height: 12),

                          // ── Rules & Restrictions ─────────────────────────
                          Text(
                            AppLocalizations.of(context)!.rulesAndRestrictions,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SheetField(
                            controller: noticeCtrl,
                            label: AppLocalizations.of(
                              context,
                            )!.noticePeriodDays,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _SheetField(
                            controller: minTenureCtrl,
                            label: AppLocalizations.of(context)!.minTenureDays,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          _SheetField(
                            controller: maxConsecutiveCtrl,
                            label: AppLocalizations.of(
                              context,
                            )!.maxConsecutiveDays,
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 12),

                          // Gender restriction
                          Text(
                            AppLocalizations.of(context)!.genderRestriction,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: genderSpecific,
                            decoration: _dropDec(),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  AppLocalizations.of(context)!.allGenders,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text(
                                  AppLocalizations.of(context)!.maleOnly,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text(
                                  AppLocalizations.of(context)!.femaleOnly,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (v) => setSt(() => genderSpecific = v!),
                          ),

                          const SizedBox(height: 16),

                          // ── Toggles ──────────────────────────────────────
                          Text(
                            AppLocalizations.of(context)!.options,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            value: isPaid,
                            onChanged: (v) => setSt(() => isPaid = v ?? true),
                            title: Text(
                              AppLocalizations.of(context)!.paidLeave,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          CheckboxListTile(
                            value: allowHalfDay,
                            onChanged: (v) =>
                                setSt(() => allowHalfDay = v ?? false),
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.allowHalfDayRequests,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          CheckboxListTile(
                            value: requiresDocument,
                            onChanged: (v) =>
                                setSt(() => requiresDocument = v ?? false),
                            title: Text(
                              AppLocalizations.of(context)!.requiresDocument,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          if (isEdit)
                            CheckboxListTile(
                              value: isActive,
                              onChanged: (v) =>
                                  setSt(() => isActive = v ?? true),
                              title: Text(
                                AppLocalizations.of(context)!.activeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.success,
                            ),

                          const SizedBox(height: 24),

                          // ── Save Button ──────────────────────────────────
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
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                try {
                                  final repo = ref.read(
                                    adminOpsRepositoryProvider,
                                  );
                                  if (isEdit) {
                                    await repo.updateLeaveType(type.id, {
                                      'name': nameCtrl.text.trim(),
                                      'code': codeCtrl.text.trim(),
                                      'days_per_year':
                                          double.tryParse(daysCtrl.text) ?? 12,
                                      'color': selectedColor,
                                      'is_paid': isPaid,
                                      'carry_forward': carryForward,
                                      'requires_document': requiresDocument,
                                      'is_active': isActive,
                                      'is_prorated': isProrated,
                                      'minimum_tenure_days':
                                          minTenureCtrl.text.isNotEmpty
                                          ? int.tryParse(minTenureCtrl.text)
                                          : null,
                                      'allow_half_day': allowHalfDay,
                                      'notice_period_days':
                                          int.tryParse(noticeCtrl.text) ?? 0,
                                      'max_consecutive_days':
                                          maxConsecutiveCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxConsecutiveCtrl.text,
                                            )
                                          : null,
                                      'sort_order':
                                          int.tryParse(sortOrderCtrl.text) ?? 0,
                                      'max_carry_forward':
                                          maxCarryForwardCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxCarryForwardCtrl.text,
                                            )
                                          : null,
                                      'gender_specific': genderSpecific,
                                    });
                                  } else {
                                    await repo.createLeaveType(
                                      name: nameCtrl.text.trim(),
                                      defaultDays:
                                          double.tryParse(daysCtrl.text) ?? 12,
                                      color: selectedColor,
                                      code: codeCtrl.text.trim(),
                                      isPaid: isPaid,
                                      carryForward: carryForward,
                                      requiresDocument: requiresDocument,
                                      isActive: isActive,
                                      isProrated: isProrated,
                                      minimumTenureDays:
                                          minTenureCtrl.text.isNotEmpty
                                          ? int.tryParse(minTenureCtrl.text)
                                          : null,
                                      allowHalfDay: allowHalfDay,
                                      noticePeriodDays:
                                          int.tryParse(noticeCtrl.text) ?? 0,
                                      maxConsecutiveDays:
                                          maxConsecutiveCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxConsecutiveCtrl.text,
                                            )
                                          : null,
                                      sortOrder:
                                          int.tryParse(sortOrderCtrl.text) ?? 0,
                                      maxCarryForward:
                                          maxCarryForwardCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxCarryForwardCtrl.text,
                                            )
                                          : null,
                                      genderSpecific: genderSpecific,
                                    );
                                  }
                                  ref.invalidate(leaveTypesProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.leaveTypeUpdated
                                              : AppLocalizations.of(
                                                  context,
                                                )!.leaveTypeCreated,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                isEdit
                                    ? AppLocalizations.of(context)!.saveChanges
                                    : AppLocalizations.of(context)!.create,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropDec() => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}

class _LeaveTypeCard extends ConsumerWidget {
  final LeaveTypeData type;
  final void Function(LeaveTypeData) onEdit;
  const _LeaveTypeCard({required this.type, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _typeColor(type.color);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
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
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accent.withAlpha(18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      type.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.grey800,
                                      ),
                                    ),
                                  ),
                                  if (type.code != null &&
                                      type.code!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: accent.withAlpha(40),
                                        ),
                                      ),
                                      child: Text(
                                        type.code!,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.daysPerYearLabel(
                                  type.defaultDays.toStringAsFixed(0),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: type.isActive
                                ? const Color(0xFFDCFCE7)
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.isActive
                                ? AppLocalizations.of(
                                    context,
                                  )!.activeLabel.toUpperCase()
                                : AppLocalizations.of(
                                    context,
                                  )!.inactiveLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: type.isActive
                                  ? AppColors.success
                                  : AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Policy badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _PolicyBadge(
                          label: type.isPaid
                              ? AppLocalizations.of(context)!.paid
                              : AppLocalizations.of(context)!.unpaid,
                          color: type.isPaid
                              ? AppColors.success
                              : AppColors.grey500,
                          bg: type.isPaid
                              ? const Color(0xFFDCFCE7)
                              : AppColors.grey100,
                        ),
                        if (type.isProrated)
                          _PolicyBadge(
                            label: AppLocalizations.of(context)!.prorated,
                            color: const Color(0xFF2563EB),
                            bg: const Color(0xFFDBEAFE),
                          ),
                        if (type.allowHalfDay)
                          _PolicyBadge(
                            label: AppLocalizations.of(context)!.halfDayBadge,
                            color: const Color(0xFF0F766E),
                            bg: const Color(0xFFCCFBF1),
                          ),
                        if (type.carryForward) ...[
                          _PolicyBadge(
                            label: type.maxCarryForward != null
                                ? AppLocalizations.of(
                                    context,
                                  )!.carryFwd(type.maxCarryForward!.toString())
                                : AppLocalizations.of(
                                    context,
                                  )!.carryForwardBadge,
                            color: const Color(0xFF7C3AED),
                            bg: const Color(0xFFF5F3FF),
                          ),
                        ],
                        if (type.maxConsecutiveDays != null)
                          _PolicyBadge(
                            label: AppLocalizations.of(
                              context,
                            )!.maxConsec(type.maxConsecutiveDays!.toString()),
                            color: const Color(0xFFB45309),
                            bg: const Color(0xFFFEF3C7),
                          ),
                        if (type.requiresDocument)
                          _PolicyBadge(
                            label: AppLocalizations.of(context)!.requiresDoc,
                            color: const Color(0xFFB45309),
                            bg: const Color(0xFFFEF3C7),
                          ),
                        if (type.genderSpecific != 'all')
                          _PolicyBadge(
                            label: AppLocalizations.of(context)!.genderBadge(
                              type.genderSpecific == 'male'
                                  ? AppLocalizations.of(context)!.maleOnly
                                  : AppLocalizations.of(context)!.femaleOnly,
                            ),
                            color: AppColors.grey600,
                            bg: AppColors.grey100,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Additional info row
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noticeSort(
                            type.noticePeriodDays.toString(),
                            type.sortOrder.toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                        if (type.minimumTenureDays != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.minTenureBadge(
                              type.minimumTenureDays!.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Footer: edit & delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => onEdit(type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.edit,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _confirmDelete(context, ref, type.id, type.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  size: 13,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  AppLocalizations.of(context)!.deleteLeaveType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.grey800,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(
                          context,
                        )!.deleteLeaveTypeConfirm(name),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppLocalizations.of(context)!.delete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteLeaveType(id);

        ref.invalidate(leaveTypesProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.leaveTypeDeleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _PolicyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _PolicyBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _GradientFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GradientFAB({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(70),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;
  const _SheetField({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.grey600,
        ),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyPlaceholder({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.nothingToShow,
            style: const TextStyle(fontSize: 13, color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.failedToLoadData,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context)!.tryAgain),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
