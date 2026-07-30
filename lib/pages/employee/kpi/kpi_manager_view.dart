import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'kpi_shared_components.dart';

class KpiManagerView extends StatelessWidget {
  final KpiData data;

  const KpiManagerView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        KpiSharedComponents.buildSummaryCard(
          title: l10n.branchAverageScore,
          score: data.metrics.branchAverage,
          subtitle: l10n.aggregatedFromTeam,
          color: Colors.indigo,
          icon: Icons.group,
        ),
        Expanded(
          child: KpiSharedComponents.buildKpiList(
            context: context,
            kpis: data.managerKpis,
            themeColor: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
