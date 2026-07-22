import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/providers/kpi_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';

import 'kpi/kpi_employee_view.dart';
import 'kpi/kpi_manager_view.dart';
import 'kpi/kpi_owner_view.dart';
import 'kpi/kpi_super_admin_view.dart';

class KpiScreen extends ConsumerStatefulWidget {
  const KpiScreen({super.key});

  @override
  ConsumerState<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends ConsumerState<KpiScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _tabCount = 1;

  void _initTabs(KpiData data) {
    final isSuperAdmin = data.userRole == 'super_admin';
    final isOwner = data.userRole == 'company_owner' || data.userRole == 'company_admin';
    final isManager = data.userRole == 'branch_manager' || isOwner;

    int newTabCount = 1;
    if (!isSuperAdmin) {
      if (isManager) newTabCount = 2;
      if (isOwner) newTabCount = 3;
    }

    if (_tabController == null || _tabCount != newTabCount) {
      _tabCount = newTabCount;
      _tabController?.dispose();
      _tabController = TabController(length: _tabCount, vsync: this, initialIndex: _tabCount - 1);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(systemKpisProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: kpisAsync.when(
        data: (data) {
          _initTabs(data);

          final isSuperAdmin = data.userRole == 'super_admin';
          final isOwner = data.userRole == 'company_owner' || data.userRole == 'company_admin';
          final isManager = data.userRole == 'branch_manager' || isOwner;

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              title: Text(isSuperAdmin ? 'Platform Health' : 'Performance KPIs', style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.grey900),
              bottom: isSuperAdmin ? null : TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey500,
                indicatorColor: AppColors.primary,
                tabs: [
                  if (!isSuperAdmin) const Tab(text: 'My Perf.'),
                  if (!isSuperAdmin && isManager) const Tab(text: 'Team'),
                  if (!isSuperAdmin && isOwner) const Tab(text: 'Company'),
                ],
              ),
            ),
            body: isSuperAdmin
              ? KpiSuperAdminView(data: data)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    if (!isSuperAdmin) KpiEmployeeView(data: data),
                    if (!isSuperAdmin && isManager) KpiManagerView(data: data),
                    if (!isSuperAdmin && isOwner) KpiOwnerView(data: data),
                  ],
                ),
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Performance KPIs', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: const Center(child: LoadingIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Performance KPIs', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.danger))),
        ),
      ),
    );
  }
}
