import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/branch_switch_provider.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'branch_payroll_settings_screen.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

// ── Scoped providers for branch-specific data ─────────────────────────────────

/// Dashboard KPI stats scoped to a branch.
final branchDashboardStatsProvider = FutureProvider.autoDispose.family<DashboardKpiData, int>((ref, branchId) {
  return ref.watch(adminOpsRepositoryProvider).getDashboardStats(branchId: branchId);
});

/// Leave requests scoped to a branch.
final branchLeaveRequestsProvider = FutureProvider.autoDispose.family<List<AdminLeaveRequestData>, int>((ref, branchId) {
  return ref.watch(adminOpsRepositoryProvider).getAllLeaveRequests(branchId: branchId);
});

// ── Branch Manager View Screen ────────────────────────────────────────────────

class BranchManagerViewScreen extends ConsumerWidget {
  const BranchManagerViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchSwitchProvider);
    final branchId = branchState.activeBranchId;
    final branchName = branchState.activeBranchName ?? 'Branch';
    final l10n = AppLocalizations.of(context)!;

    if (branchId == null) {
      // Should never happen, but guard just in case
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.companyAdmin));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0052FF).withAlpha(20),
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFF0052FF), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branchName,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.branchManagerView,
                    style: const TextStyle(
                      color: Color(0xFF0052FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Exit branch view button
          TextButton.icon(
            onPressed: () {
              ref.read(branchSwitchProvider.notifier).exitBranchView();
              context.go(AppRoutes.companyAdmin);
            },
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF0052FF)),
            label: Text(
              l10n.exit,
              style: const TextStyle(
                color: Color(0xFF0052FF),
                fontWeight: FontWeight.w700,
                
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              // ── "Viewing as" Banner ───────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052FF), Color(0xFF0038B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052FF).withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.viewingAs(branchName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            l10n.branchManagerModeDesc,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── KPI Cards ─────────────────────────────────────────────────
              Text(
                l10n.branchOverview,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  
                ),
              ),
              const SizedBox(height: 12),

              ref.watch(branchDashboardStatsProvider(branchId)).when(
                data: (kpi) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard(context, l10n.staff, kpi.totalEmployees.toString(), Icons.people_rounded, const Color(0xFF3B82F6))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard(context, l10n.onLeave, kpi.pendingLeaves.toString(), Icons.event_busy_rounded, const Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard(context, l10n.todaysAttendance, kpi.todayAttendance.toString(), Icons.check_circle_rounded, const Color(0xFF10B981))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard(context, l10n.pendingLeaves, kpi.pendingLeaves.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF0052FF)),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${l10n.errorLoadingBranchKpis}$e', style: const TextStyle(color: AppColors.danger)),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Operations Grid ─────────────────────────────────────
              Text(
                l10n.branchOperations,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.15,
                children: [
                  _buildGridItem(
                    context,
                    title: l10n.employees,
                    description: l10n.branchStaff,
                    icon: Icons.people_rounded,
                    color: const Color(0xFF0EA5E9),
                    routePath: AppRoutes.adminEmployees,
                  ),
                  _buildGridItem(
                    context,
                    title: l10n.leaveRequests,
                    description: l10n.reviewSubmissions,
                    icon: Icons.event_busy_rounded,
                    color: const Color(0xFFEF4444),
                    routePath: AppRoutes.adminLeave,
                  ),
                  _buildGridItem(
                    context,
                    title: l10n.shiftRules,
                    description: l10n.workSchedules,
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF10B981),
                    routePath: AppRoutes.adminShifts,
                  ),
                  _buildGridItem(
                    context,
                    title: l10n.attendanceMenu,
                    description: l10n.dailyRecords,
                    icon: Icons.fingerprint_rounded,
                    color: const Color(0xFF8B5CF6),
                    routePath: AppRoutes.adminAttendance,
                  ),
                  _buildGridItem(
                    context,
                    title: l10n.payrollSettings,
                    description: l10n.rulesAndOvertime,
                    icon: Icons.calculate_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BranchPayrollSettingsScreen(branchId: branchId, branchName: branchName),
                      ));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Pending Leaves Quick List ─────────────────────────────────
              Text(
                l10n.pendingLeaveRequests,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                  
                ),
              ),
              const SizedBox(height: 12),

              ref.watch(branchLeaveRequestsProvider(branchId)).when(
                data: (requests) {
                  final pending = requests.where((r) => r.status == 'pending').take(5).toList();
                  if (pending.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Center(
                        child: Text(
                          l10n.noPendingLeaveRequests,
                          style: const TextStyle(color: AppColors.grey500,  fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((req) => _buildLeaveRequestTile(context, req)).toList(),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF0052FF)))),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),

          // ── Floating Exit Banner ────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFloatingExitBanner(context, ref, branchName, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingExitBanner(BuildContext context, WidgetRef ref, String branchName, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        ref.read(branchSwitchProvider.notifier).exitBranchView();
        context.go(AppRoutes.companyAdmin);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0052FF).withAlpha(230),
                  const Color(0xFF0038B8).withAlpha(230),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0052FF).withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.viewingTapToExit(branchName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
              ],
            ),
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
    String? routePath,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap ?? () {
        if (routePath != null) context.push(routePath);
      },
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
                color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
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

  Widget _buildLeaveRequestTile(BuildContext context, AdminLeaveRequestData req) {
    final statusColor = req.status == 'pending'
        ? AppColors.warning
        : req.status == 'approved'
            ? AppColors.success
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.employeeName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${req.leaveTypeName} · ${req.startDate} → ${req.endDate}',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              req.status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
