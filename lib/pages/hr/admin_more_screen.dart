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
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isCompanyAdmin;
    final isBranchManager = authState.isBranchManager;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Finance
            if (isAdmin) ...[
              _sectionHeader(l10n.financeSection),
              const SizedBox(height: 10),
              _buildGrid(context, [
                _MoreItem(l10n.morePayroll, l10n.morePayrollDesc, Icons.payments_rounded, const Color(0xFFF59E0B), AppRoutes.adminPayroll),
                _MoreItem(l10n.moreExpenses, l10n.moreExpensesDesc, Icons.receipt_long_rounded, const Color(0xFFEC4899), AppRoutes.adminExpenses),
              ]),
              const SizedBox(height: 20),
            ],

            // ── Operations
            if (isAdmin || isBranchManager) ...[
              _sectionHeader(l10n.operationsSection),
              const SizedBox(height: 10),
              _buildGrid(context, [
                if (isAdmin || isBranchManager)
                  _MoreItem(l10n.moreShifts, l10n.moreShiftsDesc, Icons.schedule_rounded, const Color(0xFF10B981), AppRoutes.adminShifts),
                if (isAdmin)
                  _MoreItem(l10n.moreHolidays, l10n.moreHolidaysDesc, Icons.celebration_rounded, const Color(0xFFEAB308), AppRoutes.adminHolidays),
                if (isAdmin)
                  _MoreItem(l10n.moreAssets, l10n.moreAssetsDesc, Icons.devices_rounded, const Color(0xFF6B7280), AppRoutes.adminAssets),
                if (isAdmin)
                  _MoreItem(l10n.moreAnnouncements, l10n.moreAnnouncementsDesc, Icons.campaign_rounded, const Color(0xFF8B5CF6), AppRoutes.adminSendNotification),
              ]),
              const SizedBox(height: 20),
            ],

            // ── Talent
            if (isAdmin) ...[
              _sectionHeader(l10n.talentSection),
              const SizedBox(height: 10),
              _buildGrid(context, [
                _MoreItem(l10n.moreRecruitment, l10n.moreRecruitmentDesc, Icons.work_outline_rounded, const Color(0xFF0052FF), AppRoutes.adminRecruitment),
                _MoreItem(l10n.morePerformance, l10n.morePerformanceDesc, Icons.trending_up_rounded, const Color(0xFFA855F7), AppRoutes.adminPerformance),
                _MoreItem(l10n.moreReports, l10n.moreReportsDesc, Icons.assessment_rounded, const Color(0xFF14B8A6), AppRoutes.adminReports),
                _MoreItem(l10n.moreDocuments, l10n.moreDocumentsDesc, Icons.folder_open_rounded, const Color(0xFFF59E0B), AppRoutes.adminDocuments),
              ]),
              const SizedBox(height: 20),
            ],

            // ── System
            if (isAdmin) ...[
              _sectionHeader(l10n.systemSection),
              const SizedBox(height: 10),
              _buildGrid(context, [
                _MoreItem(l10n.moreRoles, l10n.moreRolesDesc, Icons.admin_panel_settings_rounded, const Color(0xFF6366F1), AppRoutes.adminRoles),
                _MoreItem(l10n.moreNotifications, l10n.moreNotificationsDesc, Icons.notifications_rounded, const Color(0xFFEF4444), AppRoutes.notifications),
                _MoreItem(l10n.morePolicies, l10n.morePoliciesDesc, Icons.book_rounded, const Color(0xFF3B82F6), AppRoutes.adminPolicies),
                _MoreItem(l10n.moreHrStructure, l10n.moreHrStructureDesc, Icons.corporate_fare_rounded, const Color(0xFF6366F1), AppRoutes.hrStructure),
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
                          _sectionHeader(l10n.branchSection),
                          const SizedBox(height: 10),
                          _BranchSwitcherTile(branches: branches),
                          const SizedBox(height: 20),
                        ],
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

            // ── Divider before logout
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 20),

            // ── Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showLogoutConfirmation(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: Text(
                  l10n.logoutBtn,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
      childAspectRatio: 2.15,
      children: items.map((item) => _buildGridItem(context, item)).toList(),
    );
  }

  Widget _buildGridItem(BuildContext context, _MoreItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.grey200.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, color: item.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary(context).withAlpha(5), blurRadius: 8, offset: Offset(0, 3)),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: branch.address != null
                ? Text(branch.address!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11))
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
