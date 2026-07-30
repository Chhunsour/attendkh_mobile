import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'kpi_shared_components.dart';

class KpiEmployeeView extends StatelessWidget {
  final KpiData data;

  const KpiEmployeeView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        KpiSharedComponents.buildSummaryCard(
          title: l10n.overallSystemScore,
          score: data.metrics.overallScore,
          subtitle: l10n.basedOnDynamicData,
          color: Colors.blue,
          icon: Icons.track_changes,
        ),
        Expanded(
          child: KpiSharedComponents.buildKpiList(
            context: context,
            kpis: data.employeeKpis,
            themeColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
