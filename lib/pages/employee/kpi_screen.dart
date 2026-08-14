import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/providers/kpi_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
    final isManager = data.userRole == 'branch_manager';

    int newTabCount = 1;
    if (!isSuperAdmin && !isOwner) {
      if (isManager) newTabCount = 2;
    }

    if (_tabController == null || _tabCount != newTabCount) {
      _tabCount = newTabCount;
      _tabController?.dispose();
      _tabController = TabController(length: _tabCount, vsync: this, initialIndex: 0);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: kpisAsync.when(
        data: (data) {
          _initTabs(data);

          final isSuperAdmin = data.userRole == 'super_admin';
          final isOwner = data.userRole == 'company_owner' || data.userRole == 'company_admin';
          final isManager = data.userRole == 'branch_manager';

          return Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              title: Text(
                isSuperAdmin ? l10n.platformHealth : l10n.performanceKpis,
                style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
                  tooltip: 'Refresh',
                  onPressed: () => ref.invalidate(systemKpisProvider),
                ),
              ],
              bottom: (isSuperAdmin || isOwner)
                  ? null
                  : TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.grey500,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                      tabs: [
                        if (!isSuperAdmin && !isOwner) Tab(text: l10n.myPerf),
                        if (!isSuperAdmin && !isOwner && isManager) Tab(text: l10n.team),
                      ],
                    ),
            ),
            body: isSuperAdmin
                ? KpiSuperAdminView(data: data)
                : isOwner
                    ? KpiOwnerView(data: data)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          if (!isSuperAdmin && !isOwner) KpiEmployeeView(data: data),
                          if (!isSuperAdmin && !isOwner && isManager) KpiManagerView(data: data),
                        ],
                      ),
          );
        },
        loading: () => Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(l10n.performanceKpis, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          body: const Center(child: LoadingIndicator(message: 'Loading KPIs...')),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(l10n.performanceKpis, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40, color: AppColors.grey400),
                const SizedBox(height: 8),
                Text('Failed to load KPIs: $error', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(systemKpisProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
