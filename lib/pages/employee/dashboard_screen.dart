import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/dashboard_provider.dart';
import 'package:mpg_hr_mobile_app/services/dashboard_repository.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadAsync = ref.watch(unreadCountProvider);
              return IconButton(
                icon: unreadAsync.maybeWhen(
                  data: (count) => count > 0
                      ? Badge(
                          label: Text('$count'),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                  orElse: () => const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => context.push(AppRoutes.notifications),
              );
            },
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => _buildContent(context, ref, data),
        loading: () => const LoadingIndicator(message: 'Loading dashboard...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
                const SizedBox(height: 12),
                Text('Failed to load dashboard', style: const TextStyle(color: AppColors.grey600)),
                const SizedBox(height: 4),
                Text(error.toString(), style: const TextStyle(fontSize: 12, color: AppColors.grey400), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DashboardData data) {
    final kpis = data.kpis;
    final authState = ref.read(authProvider);
    final isAdmin = authState.roles.any((r) => ['company_admin', 'company_owner', 'admin', 'owner'].contains(r));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Premium Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withAlpha(50),
                          child: Text(
                            data.userName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning,',
                                style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(200)),
                              ),
                              Text(
                                '${data.userName.split(' ').first} 👋',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data.companyName ?? 'Your Workspace',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Quick Actions
              const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.access_time,
                      label: 'Clock In',
                      color: AppColors.success,
                      onTap: () => context.push(AppRoutes.attendance),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.event_note,
                      label: 'Request Leave',
                      color: AppColors.secondary,
                      onTap: () => context.push(AppRoutes.leaveRequest),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long,
                      label: 'Expense',
                      color: AppColors.warning,
                      onTap: () => context.push(AppRoutes.expense),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Cards
              const Text('Today\'s Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _KPICard(title: 'Attendance', value: kpis.todayAttendance.toString(), icon: Icons.check_circle, color: AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _KPICard(title: 'Open Jobs', value: kpis.openJobs.toString(), icon: Icons.work, color: AppColors.warning)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _KPICard(title: 'Assets', value: kpis.assignedAssets.toString(), icon: Icons.inventory_2, color: AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(child: _KPICard(title: 'Total Assets', value: kpis.totalAssets.toString(), icon: Icons.warehouse, color: AppColors.danger)),
                ],
              ),

              // Pending items
              if (kpis.pendingLeaves > 0 || kpis.pendingExpenses > 0) ...[
                const SizedBox(height: 24),
                const Text('Pending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
                const SizedBox(height: 12),
                if (kpis.pendingLeaves > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withAlpha(51)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_busy, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Text('${kpis.pendingLeaves} pending leave request(s)', style: const TextStyle(fontSize: 14, color: AppColors.grey700)),
                      ],
                    ),
                  ),
                if (kpis.pendingExpenses > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withAlpha(51)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Text('${kpis.pendingExpenses} pending expense(s)', style: const TextStyle(fontSize: 14, color: AppColors.grey700)),
                      ],
                    ),
                  ),
              ],

              // Total employees
              if (kpis.totalEmployees > 0) ...[
                const SizedBox(height: 16),
                Text(
                  '${kpis.totalEmployees} total employees',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey400),
                ),
              ],

              const SizedBox(height: 24),

              // Menu Grid header
              const Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            ]),
          ),
        ),

        // Menu Grid as sliver
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildListDelegate([
              if (isAdmin) _MenuItem(icon: Icons.admin_panel_settings, label: 'Admin Panel', onTap: () => context.push(AppRoutes.companyAdmin)),
              _MenuItem(icon: Icons.people_outline, label: 'Directory', onTap: () => context.push(AppRoutes.directory)),
              _MenuItem(icon: Icons.folder_outlined, label: 'Documents', onTap: () => context.push(AppRoutes.documents)),
              _MenuItem(icon: Icons.campaign_outlined, label: 'Announce.', onTap: () => context.push(AppRoutes.announcements)),
              _MenuItem(icon: Icons.chat_outlined, label: 'AI Chat', onTap: () => context.push(AppRoutes.chat)),
              _MenuItem(icon: Icons.calendar_month_outlined, label: 'Holidays', onTap: () => context.push(AppRoutes.holidays)),
              _MenuItem(icon: Icons.policy_outlined, label: 'Policies', onTap: () => context.push(AppRoutes.policies)),
              _MenuItem(icon: Icons.schedule_outlined, label: 'Shifts', onTap: () => context.push(AppRoutes.shifts)),
              _MenuItem(icon: Icons.receipt_long_outlined, label: 'Expenses', onTap: () => context.push(AppRoutes.expense)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.grey600, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }
}