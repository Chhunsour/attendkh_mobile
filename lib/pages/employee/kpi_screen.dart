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
      backgroundColor: AppColors.backgroundLight,
      body: kpisAsync.when(
        data: (data) {
          _initTabs(data);

          final isSuperAdmin = data.userRole == 'super_admin';
          final isOwner = data.userRole == 'company_owner' || data.userRole == 'company_admin';
          final isManager = data.userRole == 'branch_manager';

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              title: Text(isSuperAdmin ? l10n.platformHealth : l10n.performanceKpis, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.grey900),
              bottom: (isSuperAdmin || isOwner) ? null : TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey500,
                indicatorColor: AppColors.primary,
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
          appBar: AppBar(
            title: Text(l10n.performanceKpis, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: const Center(child: LoadingIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.performanceKpis, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.danger))),
        ),
      ),
    );
  }
}
