import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

class CompanyAdminDashboardScreen extends ConsumerWidget {
  const CompanyAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
              _buildGridItem(
                context,
                title: 'HR Structure',
                description: 'Depts & branches',
                icon: Icons.corporate_fare_rounded,
                color: const Color(0xFF6366F1),
                routePath: AppRoutes.hrStructure,
              ),
              _buildGridItem(
                context,
                title: 'Employees',
                description: 'Manage staff',
                icon: Icons.people_rounded,
                color: const Color(0xFF0EA5E9),
                routePath: AppRoutes.adminEmployees,
              ),
              _buildGridItem(
                context,
                title: 'Shift Rules',
                description: 'Work schedules',
                icon: Icons.schedule_rounded,
                color: const Color(0xFF10B981),
                routePath: AppRoutes.adminShifts,
              ),
              _buildGridItem(
                context,
                title: 'Leave Requests',
                description: 'Review submissions',
                icon: Icons.event_busy_rounded,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.adminLeave,
              ),
              _buildGridItem(
                context,
                title: 'Payroll',
                description: 'Process runs',
                icon: Icons.payments_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminPayroll,
              ),
              _buildGridItem(
                context,
                title: 'Expense Claims',
                description: 'Review claims',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFEC4899),
                routePath: AppRoutes.adminExpenses,
              ),
              _buildGridItem(
                context,
                title: 'Assets',
                description: 'Devices & stock',
                icon: Icons.devices_rounded,
                color: const Color(0xFF6B7280),
                routePath: AppRoutes.adminAssets,
              ),
              _buildGridItem(
                context,
                title: 'Announcements',
                description: 'Broadcast alerts',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF8B5CF6),
                routePath: AppRoutes.adminSendNotification,
              ),
              _buildGridItem(
                context,
                title: 'Recruitment',
                description: 'Jobs & candidates',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFFF97316),
                routePath: AppRoutes.adminRecruitment,
              ),
              _buildGridItem(
                context,
                title: 'Performance',
                description: 'Reviews & training',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFFA855F7),
                routePath: AppRoutes.adminPerformance,
              ),
              _buildGridItem(
                context,
                title: 'Reports',
                description: 'Analytics & exports',
                icon: Icons.assessment_rounded,
                color: const Color(0xFF14B8A6),
                routePath: AppRoutes.adminReports,
              ),
              _buildGridItem(
                context,
                title: 'Documents',
                description: 'Company files',
                icon: Icons.folder_open_rounded,
                color: const Color(0xFFF59E0B),
                routePath: AppRoutes.adminDocuments,
              ),
              _buildGridItem(
                context,
                title: 'Policies',
                description: 'Rules & guidelines',
                icon: Icons.book_rounded,
                color: const Color(0xFF3B82F6),
                routePath: AppRoutes.adminPolicies,
              ),
              _buildGridItem(
                context,
                title: 'Notifications',
                description: 'View inbox',
                icon: Icons.notifications_rounded,
                color: const Color(0xFFEF4444),
                routePath: AppRoutes.adminNotifications,
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
