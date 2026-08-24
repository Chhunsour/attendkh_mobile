import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/performance/reviews/reviews_tab.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/performance/kpis/admin_kpis_tab.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/performance/training/training_tab.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.performanceTrainingTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfaceLight,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: l10n.tabReviews),
                Tab(text: l10n.tabKpis),
                Tab(text: l10n.tabTraining),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ReviewsTab(),
                AdminKpisTab(),
                TrainingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
