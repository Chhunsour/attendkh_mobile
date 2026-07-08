import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_form_screen.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';

// Status config
const _statusConfig = {
  'active':     _StatusCfg(Color(0xFF16A34A), Color(0xFFDCFCE7), Icons.check_circle_rounded),
  'inactive':   _StatusCfg(Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.pause_circle_rounded),
  'terminated': _StatusCfg(Color(0xFFDC2626), Color(0xFFFEE2E2), Icons.cancel_rounded),
  'resigned':   _StatusCfg(Color(0xFFCA8A04), Color(0xFFFEF9C3), Icons.logout_rounded),
  'on_leave':   _StatusCfg(Color(0xFF2563EB), Color(0xFFDBEAFE), Icons.beach_access_rounded),
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
  ConsumerState<AdminEmployeeDetailScreen> createState() => _AdminEmployeeDetailScreenState();
}

class _AdminEmployeeDetailScreenState extends ConsumerState<AdminEmployeeDetailScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.grey800),
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          detailAsync.whenData((emp) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminEmployeeFormScreen(employee: emp),
                  ),
                );
                ref.invalidate(employeeDetailProvider(widget.employee.id));
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
              ),
              tooltip: 'Edit Employee',
            ),
          )).value ?? const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        data: (richEmployee) => _buildDetailContent(context, richEmployee),
        loading: () => const LoadingIndicator(message: 'Loading profile details...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text('Failed to load profile details.', style: TextStyle(color: AppColors.grey600)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(employeeDetailProvider(widget.employee.id)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, EmployeeData emp) {
    final status = emp.employmentStatus ?? emp.status ?? 'active';
    final cfg = _statusConfig[status] ?? const _StatusCfg(Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.help_outline_rounded);

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
                      border: Border.all(color: cfg.color.withAlpha(60), width: 3),
                    ),
                    child: emp.avatar != null
                        ? ClipOval(child: Image.network(emp.avatar!, fit: BoxFit.cover))
                        : Center(
                            child: Text(
                              emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : 'E',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cfg.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cfg.color.withAlpha(60), width: 1.5),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey800),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      emp.position ?? 'No Position',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emp.department ?? 'No Department',
                    style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w500),
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Info', icon: Icon(Icons.info_outline_rounded, size: 20)),
              Tab(text: 'Leaves', icon: Icon(Icons.calendar_today_rounded, size: 20)),
              Tab(text: 'Logs', icon: Icon(Icons.history_rounded, size: 20)),
              Tab(text: 'Contact', icon: Icon(Icons.contact_phone_rounded, size: 20)),
            ],
          ),
        ),

        // ── Tab Views ──────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(emp),
              _buildLeavesTab(emp),
              _buildAttendanceTab(emp),
              _buildEmergencyTab(emp),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(EmployeeData emp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Employment details'),
          _buildInfoCard([
            _buildDetailRow(Icons.badge_outlined, 'Employee ID', emp.employeeId),
            _buildDetailRow(Icons.category_outlined, 'Employment Type', _capitalize(emp.employmentType ?? 'full_time')),
            _buildDetailRow(Icons.sensors_outlined, 'Status', _capitalize(emp.employmentStatus ?? 'active')),
            _buildDetailRow(Icons.business_rounded, 'Branch', emp.branch),
            _buildDetailRow(Icons.calendar_month_rounded, 'Join Date', formatDate(emp.joinDate)),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Personal details'),
          _buildInfoCard([
            _buildDetailRow(Icons.mail_outline_rounded, 'Email', emp.email),
            _buildDetailRow(Icons.phone_iphone_rounded, 'Phone', emp.phone),
            _buildDetailRow(Icons.face_unlock_rounded, 'Gender', _capitalize(emp.gender ?? 'Not specified')),
            _buildDetailRow(Icons.cake_outlined, 'DOB', formatDate(emp.dateOfBirth)),
            _buildDetailRow(Icons.favorite_border_rounded, 'Marital Status', _capitalize(emp.maritalStatus ?? 'Not specified')),
            _buildDetailRow(Icons.pin_outlined, 'National ID', emp.nationalId),
            _buildDetailRow(Icons.home_outlined, 'Address', emp.address),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Payroll & Salary'),
          _buildInfoCard([
            _buildDetailRow(Icons.monetization_on_outlined, 'Monthly Salary', emp.salary != null ? '\$${emp.salary!.toStringAsFixed(2)}' : null),
            _buildDetailRow(Icons.account_balance_outlined, 'Bank Name', emp.bankName),
            _buildDetailRow(Icons.account_box_outlined, 'Bank Account', emp.bankAccount),
          ]),
          if (emp.notes != null && emp.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Admin Notes'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                border: Border.all(color: AppColors.grey200),
              ),
              child: Text(
                emp.notes!,
                style: const TextStyle(fontSize: 14, color: AppColors.grey700, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeavesTab(EmployeeData emp) {
    final balances = emp.leaveBalances ?? [];
    final requests = emp.recentLeaveRequests ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Leave Balances'),
          if (balances.isEmpty)
            _buildEmptyState('No leave balances allocated.')
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.grey200),
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
                            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bal.leaveTypeName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat('Allocated', total.toStringAsFixed(1)),
                          _buildMiniStat('Used', bal.usedDays.toStringAsFixed(1)),
                          _buildMiniStat('Remaining', remaining.toStringAsFixed(1), highlight: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 28),
          _buildSectionHeader('Recent Leave Requests'),
          if (requests.isEmpty)
            _buildEmptyState('No recent leave requests.')
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey800),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event_outlined, size: 13, color: AppColors.grey400),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formatDateRange(req.startDate, req.endDate),
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
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

  Widget _buildAttendanceTab(EmployeeData emp) {
    final logs = emp.recentAttendances ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recent Attendance logs'),
          if (logs.isEmpty)
            _buildEmptyState('No attendance logs found.')
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDate(log.date),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey800),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.login_rounded, size: 12, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatTime(log.clockIn),
                                        style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 12, color: AppColors.danger),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatTime(log.clockOut),
                                        style: const TextStyle(fontSize: 12, color: AppColors.grey700, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusCol.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusCol.withAlpha(60)),
                        ),
                        child: Text(
                          log.status.toUpperCase(),
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

  Widget _buildEmergencyTab(EmployeeData emp) {
    final contact = emp.emergencyContact;
    final name = contact?['name'] as String?;
    final rel = contact?['relationship'] as String?;
    final phone = contact?['phone'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Emergency Contact details'),
          if (contact == null || (name == null && phone == null))
            _buildEmptyState('No emergency contact info provided.')
          else
            _buildInfoCard([
              _buildDetailRow(Icons.person_outline_rounded, 'Contact Name', name),
              _buildDetailRow(Icons.people_outline_rounded, 'Relationship', rel),
              _buildDetailRow(Icons.phone_iphone_rounded, 'Phone Number', phone),
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
        border: Border.all(color: AppColors.grey200),
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
            style: const TextStyle(fontSize: 14, color: AppColors.grey600, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, color: AppColors.grey800, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primary : AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.grey400, fontWeight: FontWeight.w500),
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
        return Colors.orange;
      case 'absent':
        return AppColors.danger;
      default:
        return AppColors.grey500;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
