import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'kpi_shared_components.dart';

class KpiOwnerView extends StatelessWidget {
  final KpiData data;

  const KpiOwnerView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KpiSharedComponents.buildSummaryCard(
          title: 'Global Health Score',
          score: data.metrics.companyAverage,
          subtitle: 'Aggregated across all branches',
          color: Colors.purple,
          icon: Icons.business,
        ),
        Expanded(
          child: KpiSharedComponents.buildKpiList(
            kpis: data.ownerKpis,
            themeColor: Colors.purple,
          ),
        ),
      ],
    );
  }
}
