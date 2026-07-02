import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/dashboard/presentation/dashboard_provider.dart';
import 'package:mpg_hr_mobile_app/features/dashboard/data/dashboard_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => _buildContent(context, data),
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

  Widget _buildContent(BuildContext context, DashboardData data) {
    final kpis = data.kpis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${data.userName.split(' ').first}! 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  data.companyName ?? 'Your workspace',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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

          // KPI Cards — now using real data
          const Text('Today\'s Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _KPICard(title: 'Present', value: kpis.presentToday.toString(), icon: Icons.check_circle, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _KPICard(title: 'Late', value: kpis.lateToday.toString(), icon: Icons.warning_amber, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _KPICard(title: 'On Leave', value: kpis.onLeaveToday.toString(), icon: Icons.beach_access, color: AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: _KPICard(title: 'Absent', value: kpis.absentToday.toString(), icon: Icons.cancel, color: AppColors.danger)),
            ],
          ),

          // Pending items
          if (kpis.pendingLeaveRequests > 0 || kpis.pendingExpenses > 0) ...[
            const SizedBox(height: 24),
            const Text('Pending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            const SizedBox(height: 12),
            if (kpis.pendingLeaveRequests > 0)
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
                    Text('${kpis.pendingLeaveRequests} pending leave request(s)', style: const TextStyle(fontSize: 14, color: AppColors.grey700)),
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

          // Menu Grid
          const Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _MenuItem(icon: Icons.people_outline, label: 'Directory', onTap: () => context.push(AppRoutes.directory)),
              _MenuItem(icon: Icons.folder_outlined, label: 'Documents', onTap: () => context.push(AppRoutes.documents)),
              _MenuItem(icon: Icons.campaign_outlined, label: 'Announce.', onTap: () => context.push(AppRoutes.announcements)),
              _MenuItem(icon: Icons.chat_outlined, label: 'AI Chat', onTap: () => context.push(AppRoutes.chat)),
              _MenuItem(icon: Icons.calendar_month_outlined, label: 'Calendar', onTap: () {}),
              _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800)),
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
            ],
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