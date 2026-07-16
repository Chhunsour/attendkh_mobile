import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isCompanyAdmin;
    final isBranchManager = authState.isBranchManager;

    return Scaffold(
      backgroundColor:  Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Finance
          if (isAdmin) ...[
            _sectionHeader('Finance'),
            const SizedBox(height: 10),
            _buildGrid(context, [
              _MoreItem('Payroll', 'Process runs', Icons.payments_rounded, const Color(0xFFF59E0B), AppRoutes.adminPayroll),
              _MoreItem('Expenses', 'Review claims', Icons.receipt_long_rounded, const Color(0xFFEC4899), AppRoutes.adminExpenses),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Operations
          if (isAdmin || isBranchManager) ...[
            _sectionHeader('Operations'),
            const SizedBox(height: 10),
            _buildGrid(context, [
              if (isAdmin || isBranchManager)
                _MoreItem('Shifts', 'Work schedules', Icons.schedule_rounded, const Color(0xFF10B981), AppRoutes.adminShifts),
              if (isAdmin)
                _MoreItem('Holidays', 'Company holidays', Icons.celebration_rounded, const Color(0xFFEAB308), AppRoutes.adminHolidays),
              if (isAdmin)
                _MoreItem('Assets', 'Devices & stock', Icons.devices_rounded, const Color(0xFF6B7280), AppRoutes.adminAssets),
              if (isAdmin)
                _MoreItem('Announcements', 'Broadcast alerts', Icons.campaign_rounded, const Color(0xFF8B5CF6), AppRoutes.adminSendNotification),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Talent
          if (isAdmin) ...[
            _sectionHeader('Talent'),
            const SizedBox(height: 10),
            _buildGrid(context, [
              _MoreItem('Recruitment', 'Jobs & candidates', Icons.work_outline_rounded, const Color(0xFFF97316), AppRoutes.adminRecruitment),
              _MoreItem('Performance', 'Reviews & training', Icons.trending_up_rounded, const Color(0xFFA855F7), AppRoutes.adminPerformance),
              _MoreItem('Reports', 'Analytics & exports', Icons.assessment_rounded, const Color(0xFF14B8A6), AppRoutes.adminReports),
              _MoreItem('Documents', 'Company files', Icons.folder_open_rounded, const Color(0xFFF59E0B), AppRoutes.adminDocuments),
            ]),
            const SizedBox(height: 20),
          ],

          // ── System
          if (isAdmin) ...[
            _sectionHeader('System'),
            const SizedBox(height: 10),
            _buildGrid(context, [
              _MoreItem('Roles', 'Permissions', Icons.admin_panel_settings_rounded, const Color(0xFF6366F1), AppRoutes.adminRoles),
              _MoreItem('Notifications', 'View inbox', Icons.notifications_rounded, const Color(0xFFEF4444), AppRoutes.notifications),
              _MoreItem('Policies', 'Rules & guidelines', Icons.book_rounded, const Color(0xFF3B82F6), AppRoutes.adminPolicies),
              _MoreItem('HR Structure', 'Depts & branches', Icons.corporate_fare_rounded, const Color(0xFF6366F1), AppRoutes.hrStructure),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Branch Switcher (Company Admin only)
          if (isAdmin)
            ref.watch(branchesProvider).when(
              data: (branches) => branches.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Branch'),
                        const SizedBox(height: 10),
                        _BranchSwitcherTile(branches: branches),
                        const SizedBox(height: 20),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

          // ── Divider before logout
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),

          // ── Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showLogoutConfirmation(context, ref),
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.danger, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.dangerLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.grey400,
        letterSpacing: 1.2,
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_MoreItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: items.map((item) => _buildGridItem(context, item)).toList(),
    );
  }

  Widget _buildGridItem(BuildContext context, _MoreItem item) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
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

class _MoreItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  const _MoreItem(this.title, this.description, this.icon, this.color, this.route);
}

/// Tile that shows branch switcher inline in the More screen
class _BranchSwitcherTile extends ConsumerWidget {
  final List<BranchData> branches;
  const _BranchSwitcherTile({required this.branches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: branches.map((branch) {
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 18),
            ),
            title: Text(
              branch.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
            ),
            subtitle: branch.address != null
                ? Text(branch.address!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontFamily: 'Inter'))
                : null,
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
            onTap: () async {
              await ref.read(branchSwitchProvider.notifier).switchToBranch(branch);
              if (context.mounted) context.push(AppRoutes.branchManagerView);
            },
          );
        }).toList(),
      ),
    );
  }
}
