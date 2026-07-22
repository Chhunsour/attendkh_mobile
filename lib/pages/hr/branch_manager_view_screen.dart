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

    if (branchId == null) {
      // Should never happen, but guard just in case
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.companyAdmin));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                color: const Color(0xFFF97316).withAlpha(20),
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFFF97316), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branchName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Branch Manager View',
                    style: TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
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
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFF97316)),
            label: const Text(
              'Exit',
              style: TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
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
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withAlpha(60),
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
                            'Viewing as $branchName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const Text(
                            'You are in Branch Manager mode — data is scoped to this branch.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── KPI Cards ─────────────────────────────────────────────────
              const Text(
                'Branch Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),

              ref.watch(branchDashboardStatsProvider(branchId)).when(
                data: (kpi) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard('Staff', kpi.totalEmployees.toString(), Icons.people_rounded, const Color(0xFF3B82F6))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('On Leave', kpi.pendingLeaves.toString(), Icons.event_busy_rounded, const Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildKpiCard("Today's Attendance", kpi.todayAttendance.toString(), Icons.check_circle_rounded, const Color(0xFF10B981))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKpiCard('Pending Leaves', kpi.pendingLeaves.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFFF97316)),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Error loading branch KPIs: $e', style: const TextStyle(color: AppColors.danger)),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Operations Grid ─────────────────────────────────────
              const Text(
                'Branch Operations',
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
                    title: 'Employees',
                    description: 'Branch staff',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF0EA5E9),
                    routePath: AppRoutes.adminEmployees,
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
                    title: 'Shift Rules',
                    description: 'Work schedules',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF10B981),
                    routePath: AppRoutes.adminShifts,
                  ),
                  _buildGridItem(
                    context,
                    title: 'Attendance',
                    description: 'Daily records',
                    icon: Icons.fingerprint_rounded,
                    color: const Color(0xFF8B5CF6),
                    routePath: AppRoutes.adminEmployees,
                  ),
                  _buildGridItem(
                    context,
                    title: 'Payroll Settings',
                    description: 'Rules & overtime',
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
              const Text(
                'Pending Leave Requests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                  fontFamily: 'Inter',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: const Center(
                        child: Text(
                          '✅  No pending leave requests',
                          style: TextStyle(color: AppColors.grey500, fontFamily: 'Inter', fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((req) => _buildLeaveRequestTile(req)).toList(),
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFF97316)))),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),

          // ── Floating Exit Banner ────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildFloatingExitBanner(context, ref, branchName),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingExitBanner(BuildContext context, WidgetRef ref, String branchName) {
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
                  const Color(0xFFF97316).withAlpha(230),
                  const Color(0xFFEA580C).withAlpha(230),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withAlpha(80),
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
                    '👁  Viewing $branchName — Tap to Exit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter')),
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
    return InkWell(
      onTap: onTap ?? () {
        if (routePath != null) context.push(routePath);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 10, color: AppColors.grey500, fontFamily: 'Inter')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveRequestTile(AdminLeaveRequestData req) {
    final statusColor = req.status == 'pending'
        ? const Color(0xFFF59E0B)
        : req.status == 'approved'
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey800, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 2),
                Text(
                  '${req.leaveTypeName} · ${req.startDate} → ${req.endDate}',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontFamily: 'Inter'),
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
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }
}
