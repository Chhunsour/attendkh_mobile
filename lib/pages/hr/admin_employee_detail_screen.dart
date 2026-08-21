import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_form_screen.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

// Status config
const _statusConfig = {
  'active': _StatusCfg(
    AppColors.success,
    AppColors.successLight,
    Icons.check_circle_rounded,
  ),
  'inactive': _StatusCfg(
    AppColors.grey600,
    AppColors.grey100,
    Icons.pause_circle_rounded,
  ),
  'terminated': _StatusCfg(
    AppColors.danger,
    AppColors.dangerLight,
    Icons.cancel_rounded,
  ),
  'resigned': _StatusCfg(
    AppColors.warning,
    AppColors.warningLight,
    Icons.logout_rounded,
  ),
  'on_leave': _StatusCfg(
    AppColors.primary,
    AppColors.primaryLight,
    Icons.beach_access_rounded,
  ),
};

class _StatusCfg {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusCfg(this.color, this.bg, this.icon);
}

class AdminEmployeeDetailScreen extends ConsumerStatefulWidget {
  final EmployeeData employee;
  const AdminEmployeeDetailScreen({super.key, required this.employee});

  @override
  ConsumerState<AdminEmployeeDetailScreen> createState() =>
      _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState
    extends ConsumerState<AdminEmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(employeeDetailProvider(widget.employee.id));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
        title: Text(
          AppLocalizations.of(context)!.employeeProfile,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          detailAsync
                  .whenData(
                    (emp) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminEmployeeFormScreen(employee: emp),
                            ),
                          );
                          ref.invalidate(
                            employeeDetailProvider(widget.employee.id),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        tooltip: AppLocalizations.of(context)!.editEmployee,
                      ),
                    ),
                  )
                  .value ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        data: (richEmployee) => _buildDetailContent(context, richEmployee),
        loading: () => LoadingIndicator(
          message: AppLocalizations.of(context)!.loadingProfileDetails,
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.failedToLoadProfileDetails,
                style: const TextStyle(color: AppColors.grey600),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(employeeDetailProvider(widget.employee.id)),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, EmployeeData emp) {
    final l10n = AppLocalizations.of(context)!;
    final status = emp.employmentStatus ?? emp.status ?? 'active';
    final cfg =
        _statusConfig[status] ??
        const _StatusCfg(
          Color(0xFF6B7280),
          Color(0xFFF3F4F6),
          Icons.help_outline_rounded,
        );

    return Column(
      children: [
        // ── Top Profile Header ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cfg.color.withAlpha(60),
                        width: 3,
                      ),
                    ),
                    child: emp.avatar != null && emp.avatar!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: emp.avatar!.startsWith('http')
                                  ? emp.avatar!
                                  : '${DioClient.storageUrl}/${emp.avatar!.startsWith('/') ? emp.avatar!.substring(1) : emp.avatar!}',
                              fit: BoxFit.cover,
                              memCacheWidth: 240,
                              memCacheHeight: 240,
                              placeholder: (ctx, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                              errorWidget: (ctx, url, err) => Center(
                                child: Text(
                                  emp.name.isNotEmpty
                                      ? emp.name.substring(0, 1).toUpperCase()
                                      : 'E',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              emp.name.isNotEmpty
                                  ? emp.name.substring(0, 1).toUpperCase()
                                  : 'E',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cfg.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cfg.color.withAlpha(60),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cfg.icon, size: 10, color: cfg.color),
                          const SizedBox(width: 4),
                          Text(
                            status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: cfg.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                emp.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (emp.khmerName != null && emp.khmerName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  emp.khmerName!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      emp.position != null
                          ? '${emp.position}${emp.positionLevel != null ? ' (${emp.positionLevel})' : ''}'
                          : l10n.noPosition,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emp.department ?? l10n.noDepartment,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Quick info badges: type, branch, team ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (emp.employmentType != null)
                    _buildQuickBadge(
                      Icons.work_outline_rounded,
                      _capitalize(emp.employmentType!),
                      AppColors.secondary,
                      AppColors.secondary.withAlpha(15),
                    ),
                  if (emp.branch != null)
                    _buildQuickBadge(
                      Icons.location_on_outlined,
                      emp.branch!,
                      AppColors.grey600,
                      AppColors.grey50,
                    ),
                  if (emp.team != null)
                    _buildQuickBadge(
                      Icons.group_outlined,
                      emp.team!,
                      AppColors.grey600,
                      AppColors.grey50,
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── Tab Bar Navigation ─────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: [
              Tab(
                text: l10n.tabInfo,
                icon: const Icon(Icons.info_outline_rounded, size: 20),
              ),
              Tab(
                text: l10n.tabLeaves,
                icon: const Icon(Icons.calendar_today_rounded, size: 20),
              ),
              Tab(
                text: l10n.tabLogs,
                icon: const Icon(Icons.history_rounded, size: 20),
              ),
              Tab(
                text: l10n.tabContact,
                icon: const Icon(Icons.contact_phone_rounded, size: 20),
              ),
            ],
          ),
        ),

        // ── Tab Views ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(emp, l10n),
              _buildLeavesTab(emp, l10n),
              _buildAttendanceTab(emp, l10n),
              _buildEmergencyTab(emp, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(EmployeeData emp, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.employmentDetails),
          _buildInfoCard([
            _buildDetailRow(
              Icons.badge_outlined,
              l10n.employeeId,
              emp.employeeId,
            ),
            _buildDetailRow(
              Icons.category_outlined,
              l10n.employmentType,
              _capitalize(emp.employmentType ?? 'full_time'),
            ),
            _buildDetailRow(
              Icons.sensors_outlined,
              l10n.status,
              _capitalize(emp.employmentStatus ?? 'active'),
            ),
            _buildDetailRow(Icons.business_rounded, l10n.branch, emp.branch),
            _buildDetailRow(Icons.group_outlined, 'Team', emp.team),
            _buildDetailRow(Icons.person_outline, 'Manager', emp.manager),
            _buildDetailRow(
              Icons.calendar_month_rounded,
              l10n.joinDate,
              formatDate(emp.joinDate),
            ),
            if (emp.probationEndDate != null)
              _buildDetailRow(
                Icons.event_available_outlined,
                'Probation End',
                formatDate(emp.probationEndDate),
              ),
            if (emp.terminationDate != null)
              _buildDetailRow(
                Icons.event_busy_outlined,
                'Termination Date',
                formatDate(emp.terminationDate),
              ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.personalDetails),
          _buildInfoCard([
            _buildDetailRow(Icons.mail_outline_rounded, l10n.email, emp.email),
            _buildDetailRow(Icons.phone_iphone_rounded, l10n.phone, emp.phone),
            if (emp.phoneNumbers != null && emp.phoneNumbers!.isNotEmpty)
              _buildDetailRow(
                Icons.phone_outlined,
                'Other Phones',
                emp.phoneNumbers!.join(', '),
              ),
            _buildDetailRow(
              Icons.face_unlock_rounded,
              l10n.gender,
              _capitalize(emp.gender ?? l10n.notSpecified),
            ),
            _buildDetailRow(
              Icons.cake_outlined,
              l10n.dob,
              formatDate(emp.dateOfBirth),
            ),
            _buildDetailRow(
              Icons.favorite_border_rounded,
              l10n.maritalStatus,
              _capitalize(emp.maritalStatus ?? l10n.notSpecified),
            ),
            _buildDetailRow(
              Icons.pin_outlined,
              l10n.nationalId,
              emp.nationalId,
            ),
            _buildDetailRow(Icons.home_outlined, l10n.address, emp.address),
          ]),
          // ── National ID Images ──
          if (emp.nationalIdImages != null &&
              emp.nationalIdImages!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('National ID Images'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: emp.nationalIdImages!.map((img) {
                final url = img.startsWith('http')
                    ? img
                    : '${DioClient.storageUrl}/${img.startsWith('/') ? img.substring(1) : img}';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    memCacheHeight: 200,
                    placeholder: (_, _) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.grey100,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.grey100,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 24,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.payrollAndSalary),
          _buildInfoCard([
            _buildDetailRow(
              Icons.monetization_on_outlined,
              l10n.monthlySalary,
              emp.salary != null ? '\$${emp.salary!.toStringAsFixed(2)}' : null,
            ),
            _buildDetailRow(
              Icons.account_balance_outlined,
              l10n.bankName,
              emp.bankName,
            ),
            _buildDetailRow(
              Icons.account_box_outlined,
              l10n.bankAccount,
              emp.bankAccount,
            ),
          ]),
          // ── Documents ──
          if (emp.documents != null && emp.documents!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Documents'),
            ...emp.documents!.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      doc.split('/').last,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (emp.notes != null && emp.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.adminNotes),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                emp.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeavesTab(EmployeeData emp, AppLocalizations l10n) {
    final balances = emp.leaveBalances ?? [];
    final requests = emp.recentLeaveRequests ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.leaveBalances),
          if (balances.isEmpty)
            _buildEmptyState(l10n.noLeaveBalancesAllocated)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: balances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bal = balances[index];
                final double total = bal.allocatedDays + bal.carriedForward;
                final double remaining = total - bal.usedDays;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bal.leaveTypeName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(
                            context,
                            l10n.allocated,
                            total.toStringAsFixed(1),
                          ),
                          _buildMiniStat(
                            context,
                            l10n.used,
                            bal.usedDays.toStringAsFixed(1),
                          ),
                          _buildMiniStat(
                            context,
                            l10n.remaining,
                            remaining.toStringAsFixed(1),
                            highlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 28),
          _buildSectionHeader(l10n.recentLeaveRequests),
          if (requests.isEmpty)
            _buildEmptyState(l10n.noRecentLeaveRequests)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = requests[index];
                final statusCol = _getLeaveStatusColor(req.status);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusCol.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusCol.withAlpha(60)),
                        ),
                        child: Text(
                          req.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusCol,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.leaveType,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_outlined,
                                  size: 13,
                                  color: AppColors.grey400,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formatDateRange(req.startDate, req.endDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(EmployeeData emp, AppLocalizations l10n) {
    final logs = emp.recentAttendances ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.recentAttendanceLogs),
          if (logs.isEmpty)
            _buildEmptyState(l10n.noAttendanceLogsFound)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = logs[index];
                final statusCol = _getAttendanceStatusColor(log.status);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDate(log.date),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.login_rounded,
                                        size: 12,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatTime(log.clockIn),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.logout_rounded,
                                        size: 12,
                                        color: AppColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatTime(log.clockOut),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (log.lateMinutes != null &&
                                log.lateMinutes! > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withAlpha(15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.danger.withAlpha(40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 12,
                                      color: AppColors.danger,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${log.lateMinutes} min late',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusCol.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusCol.withAlpha(60)),
                        ),
                        child: Text(
                          _getLocalizedAttendanceStatus(
                            log.status,
                            l10n,
                          ).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusCol,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab(EmployeeData emp, AppLocalizations l10n) {
    final contact = emp.emergencyContact;
    final name = contact?['name'] as String?;
    final rel = contact?['relationship'] as String?;
    final phone = contact?['phone'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.emergencyContactDetails),
          if (contact == null || (name == null && phone == null))
            _buildEmptyState(l10n.noEmergencyContactInfoProvided)
          else
            _buildInfoCard([
              _buildDetailRow(
                Icons.person_outline_rounded,
                l10n.contactName,
                name,
              ),
              _buildDetailRow(
                Icons.people_outline_rounded,
                l10n.relationship,
                rel,
              ),
              _buildDetailRow(
                Icons.phone_iphone_rounded,
                l10n.phoneNumber,
                phone,
              ),
            ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.grey400),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlight
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.grey800),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.grey200,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.grey500 : AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getLeaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'pending':
        return AppColors.secondary;
      default:
        return AppColors.grey500;
    }
  }

  Color _getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'late':
        return AppColors.warning;
      case 'absent':
        return AppColors.danger;
      default:
        return AppColors.grey500;
    }
  }

  String _getLocalizedAttendanceStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'present':
        return l10n.present;
      case 'late':
        return l10n.late;
      case 'absent':
        return l10n.absent;
      default:
        return status;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Widget _buildQuickBadge(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
