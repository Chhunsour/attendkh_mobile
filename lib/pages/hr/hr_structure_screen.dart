import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'widgets/hr_structure/branches_tab.dart';
import 'widgets/hr_structure/departments_tab.dart';
import 'widgets/hr_structure/org_chart_tab.dart';
import 'widgets/hr_structure/positions_tab.dart';
import 'widgets/hr_structure/teams_tab.dart';

class HrStructureScreen extends ConsumerStatefulWidget {
  const HrStructureScreen({super.key});

  @override
  ConsumerState<HrStructureScreen> createState() => _HrStructureScreenState();
}

class _HrStructureScreenState extends ConsumerState<HrStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.hrStructureTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(branchesProvider);
              ref.invalidate(departmentsProvider);
              ref.invalidate(positionsProvider);
              ref.invalidate(teamsProvider);
              ref.invalidate(orgChartProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  icon: const Icon(Icons.corporate_fare_rounded, size: 18),
                  text: l10n.tabBranches,
                ),
                Tab(
                  icon: const Icon(Icons.apartment_rounded, size: 18),
                  text: l10n.tabDepts,
                ),
                Tab(
                  icon: const Icon(Icons.badge_rounded, size: 18),
                  text: l10n.tabPositions,
                ),
                Tab(
                  icon: const Icon(Icons.groups_rounded, size: 18),
                  text: l10n.tabTeams,
                ),
                Tab(
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  text: l10n.tabOrgChart,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey200),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                BranchesTab(),
                DepartmentsTab(),
                PositionsTab(),
                TeamsTab(),
                OrgChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
