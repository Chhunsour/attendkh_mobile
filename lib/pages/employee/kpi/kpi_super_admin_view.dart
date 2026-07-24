import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'kpi_shared_components.dart';

class KpiSuperAdminView extends StatelessWidget {
  final KpiData data;

  const KpiSuperAdminView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
        KpiSharedComponents.buildSummaryCard(
          title: 'Platform Global Health',
          score: data.metrics.companyAverage,
          subtitle: 'Aggregated across all registered workspaces',
          color: Colors.blue,
          icon: Icons.public,
        ),
        // Missing "Platform Summary" card added to match the web app!
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Platform Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'These are platform-wide metrics calculating the overall health, retention rates, support SLAs, and MRR (Monthly Recurring Revenue) across all active companies within the system.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Platform Strategic KPIs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
        KpiSharedComponents.buildKpiList(
          kpis: data.ownerKpis,
          themeColor: Colors.blue,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
      ),
    );
  }
}
