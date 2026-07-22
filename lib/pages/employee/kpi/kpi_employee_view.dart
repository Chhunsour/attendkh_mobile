import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'kpi_shared_components.dart';

class KpiEmployeeView extends StatelessWidget {
  final KpiData data;

  const KpiEmployeeView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KpiSharedComponents.buildSummaryCard(
          title: 'Overall System Score',
          score: data.metrics.overallScore,
          subtitle: 'Based on dynamic module data',
          color: Colors.blue,
          icon: Icons.track_changes,
        ),
        Expanded(
          child: KpiSharedComponents.buildKpiList(
            kpis: data.employeeKpis,
            themeColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
