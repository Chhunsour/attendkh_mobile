import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (richEmployee) => _buildDetailContent(context, richEmployee),
        loading: () => const LoadingIndicator(message: 'Loading profile details...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              const Text('Failed to load profile details.', style: TextStyle(color: AppColors.grey500)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(employeeDetailProvider(widget.employee.id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, EmployeeData emp) {
    return Column(
      children: [
        // Top Profile Banner Card
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withAlpha(26),
                backgroundImage: emp.avatar != null ? NetworkImage(emp.avatar!) : null,
                child: emp.avatar == null
                    ? Text(
                        emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : 'E',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                emp.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                emp.position ?? 'No Position',
                style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                emp.department ?? 'No Department',
                style: TextStyle(fontSize: 13, color: AppColors.grey500),
              ),
            ],
          ),
        ),
        
        // Tab Headers
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Leaves'),
              Tab(text: 'Attendance'),
              Tab(text: 'Emergency'),
            ],
          ),
        ),

        // Tab Views
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Employment details'),
          _buildInfoCard([
            _buildDetailRow('Employee ID', emp.employeeId),
            _buildDetailRow('Employment Type', _capitalize(emp.employmentType ?? 'full_time')),
            _buildDetailRow('Status', _capitalize(emp.employmentStatus ?? 'active')),
            _buildDetailRow('Branch', emp.branch),
            _buildDetailRow('Join Date', emp.joinDate),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Personal details'),
          _buildInfoCard([
            _buildDetailRow('Email', emp.email),
            _buildDetailRow('Phone', emp.phone),
            _buildDetailRow('Gender', _capitalize(emp.gender ?? 'Not specified')),
            _buildDetailRow('DOB', emp.dateOfBirth),
            _buildDetailRow('Marital Status', _capitalize(emp.maritalStatus ?? 'Not specified')),
            _buildDetailRow('National ID', emp.nationalId),
            _buildDetailRow('Address', emp.address),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Payroll & Salary'),
          _buildInfoCard([
            _buildDetailRow('Monthly Salary', emp.salary != null ? '\$${emp.salary!.toStringAsFixed(2)}' : null),
            _buildDetailRow('Bank Name', emp.bankName),
            _buildDetailRow('Bank Account', emp.bankAccount),
          ]),
          if (emp.notes != null && emp.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('Admin Notes'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Text(
                emp.notes!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      padding: const EdgeInsets.all(16),
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final bal = balances[index];
                final double total = bal.allocatedDays + bal.carriedForward;
                final double remaining = total - bal.usedDays;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bal.leaveTypeName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
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
          const SizedBox(height: 24),
          _buildSectionHeader('Recent Leave Requests'),
          if (requests.isEmpty)
            _buildEmptyState('No recent leave requests.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final req = requests[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getLeaveStatusColor(req.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getLeaveStatusColor(req.status),
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${req.startDate} to ${req.endDate}',
                              style: TextStyle(fontSize: 12, color: AppColors.grey500),
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
      padding: const EdgeInsets.all(16),
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.date,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.login, size: 14, color: AppColors.grey400),
                                const SizedBox(width: 4),
                                Text(
                                  log.clockIn ?? '--:--',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.logout, size: 14, color: AppColors.grey400),
                                const SizedBox(width: 4),
                                Text(
                                  log.clockOut ?? '--:--',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getAttendanceStatusColor(log.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getAttendanceStatusColor(log.status),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Emergency Contact details'),
          if (contact == null || (name == null && phone == null))
            _buildEmptyState('No emergency contact info provided.')
          else
            _buildInfoCard([
              _buildDetailRow('Contact Name', name),
              _buildDetailRow('Relationship', rel),
              _buildDetailRow('Phone Number', phone),
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.grey600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
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
          style: TextStyle(fontSize: 11, color: AppColors.grey500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: AppColors.grey400),
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
        return AppColors.info;
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
