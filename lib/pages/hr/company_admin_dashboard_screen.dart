import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';

class CompanyAdminDashboardScreen extends ConsumerWidget {
  const CompanyAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final branchSwitchState = ref.watch(branchSwitchProvider);

    return Stack(
      children: [
        _buildMainScaffold(context, ref, authState),
        // Blur overlay when switching branches
        if (branchSwitchState.isSwitching) _buildBlurOverlay(),
      ],
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withAlpha(100),
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFEDD5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF97316),
                          backgroundColor: Color(0xFFFED7AA),
                          strokeWidth: 4.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Switching Branch View…',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                          fontFamily: 'Inter',
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Loading branch data',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                          fontFamily: 'Inter',
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScaffold(BuildContext context, WidgetRef ref, AuthState authState) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
              child: const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'HR Dashboard',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        actions: [
          // ── "View as Branch" button (only for Company Admin/Owner) ──
          if (authState.isCompanyAdmin)
            ref.watch(branchesProvider).when(
              data: (branches) => branches.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
                      child: PopupMenuButton<BranchData>(
                        tooltip: 'Select a branch to impersonate',
                        offset: const Offset(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_rounded, color: Color(0xFFF97316), size: 18),
                              SizedBox(width: 6),
                              Text('Branch', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter')),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFF97316), size: 18),
                            ],
                          ),
                        ),
                        onSelected: (branch) async {
                          await ref.read(branchSwitchProvider.notifier).switchToBranch(branch);
                          if (context.mounted) {
                            context.push(AppRoutes.branchManagerView);
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            const PopupMenuItem<BranchData>(
                              enabled: false,
                              height: 30,
                              child: Text(
                                'VIEW AS BRANCH MANAGER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            ...branches.map((b) => PopupMenuItem<BranchData>(
                              value: b,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF97316).withAlpha(15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.business_rounded, color: Color(0xFFF97316), size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          b.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.grey800,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        if (b.address != null)
                                          Text(
                                            b.address!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey500,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ];
                        },
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, s) => const SizedBox.shrink(),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: () => showLogoutConfirmation(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // ── Welcome Banner
          _buildWelcomeBanner(
            name: authState.userName ?? 'Manager',
            companyName: authState.companyName ?? 'My Company',
          ),
          const SizedBox(height: 24),

          // ── Dashboard KPIs
          ref.watch(dashboardStatsProvider).when(
            data: (kpi) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard('Total Staff', kpi.totalEmployees.toString(), Icons.people, const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard('On Leave', kpi.pendingLeaves.toString(), Icons.event_busy, const Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard('Open Jobs', kpi.openJobs.toString(), Icons.work, const Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard('Assets', '${kpi.assignedAssets}/${kpi.totalAssets}', Icons.devices, const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
              child: Text('Error loading KPIs: $e', style: const TextStyle(color: AppColors.danger)),
            ),
          ),
          // ── Quick Operations Grid Menu
          const Text(
            'Quick Operations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grey800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'HR Structure',
                  description: 'Depts & branches',
                  icon: Icons.corporate_fare_rounded,
                  color: const Color(0xFF6366F1),
                  routePath: AppRoutes.hrStructure,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: 'Employees',
                  description: 'Manage staff',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF0EA5E9),
                  routePath: AppRoutes.adminEmployees,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: 'Shift Rules',
                  description: 'Work schedules',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF10B981),
                  routePath: AppRoutes.adminShifts,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Holidays',
                  description: 'Manage company holidays',
                  icon: Icons.celebration_rounded,
                  color: const Color(0xFFEAB308), // Yellow
                  routePath: AppRoutes.adminHolidays,
                ),
              if (authState.isCompanyAdmin || authState.isBranchManager)
                _buildGridItem(
                  context,
                  title: 'Leave Requests',
                  description: 'Review submissions',
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFFEF4444),
                  routePath: AppRoutes.adminLeave,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Payroll',
                  description: 'Process runs',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFFF59E0B),
                  routePath: AppRoutes.adminPayroll,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Expense Claims',
                  description: 'Review claims',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFFEC4899),
                  routePath: AppRoutes.adminExpenses,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Assets',
                  description: 'Devices & stock',
                  icon: Icons.devices_rounded,
                  color: const Color(0xFF6B7280),
                  routePath: AppRoutes.adminAssets,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Announcements',
                  description: 'Broadcast alerts',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF8B5CF6),
                  routePath: AppRoutes.adminSendNotification,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                title: 'Recruitment',
                description: 'Jobs & candidates',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFFF97316),
                routePath: AppRoutes.adminRecruitment,
              ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Performance',
                  description: 'Reviews & training',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFA855F7),
                  routePath: AppRoutes.adminPerformance,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Reports',
                  description: 'Analytics & exports',
                  icon: Icons.assessment_rounded,
                  color: const Color(0xFF14B8A6),
                  routePath: AppRoutes.adminReports,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Documents',
                  description: 'Company files',
                  icon: Icons.folder_open_rounded,
                  color: const Color(0xFFF59E0B),
                  routePath: AppRoutes.adminDocuments,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Policies',
                  description: 'Rules & guidelines',
                  icon: Icons.book_rounded,
                  color: const Color(0xFF3B82F6),
                  routePath: AppRoutes.adminPolicies,
                ),
              if (authState.isCompanyAdmin)
                _buildGridItem(
                  context,
                  title: 'Notifications',
                  description: 'View inbox',
                  icon: Icons.notifications_rounded,
                  color: const Color(0xFFEF4444),
                  routePath: AppRoutes.notifications,
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── HR Manager Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HR Portal Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Process monthly payroll runs, manage dynamic shift rosters, and approve leaves on the go.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                          height: 1.4,
                          fontFamily: 'Inter',
                        ),
                      ),
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

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner({required String name, required String companyName}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '💼  Company Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String routePath,
  }) {
    return InkWell(
      onTap: () => context.push(routePath),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
