import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'kpi_shared_components.dart';

class KpiManagerView extends StatelessWidget {
  final KpiData data;

  const KpiManagerView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KpiSharedComponents.buildSummaryCard(
          title: 'Branch Average Score',
          score: data.metrics.branchAverage,
          subtitle: 'Aggregated from team metrics',
          color: Colors.indigo,
          icon: Icons.group,
        ),
        Expanded(
          child: KpiSharedComponents.buildKpiList(
            kpis: data.managerKpis,
            themeColor: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
