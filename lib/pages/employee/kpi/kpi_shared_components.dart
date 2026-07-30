import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';

class KpiSharedComponents {
  static Widget buildSummaryCard({
    required String title,
    required num score,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text('$score%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 30),
          )
        ],
      ),
    );
  }

  static Widget buildKpiList({
    required BuildContext context,
    required List<KpiItem> kpis,
    required Color themeColor,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (kpis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(l10n.noKpisFound, style: const TextStyle(color: AppColors.grey600)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.all(16),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        final isMock = kpi.type == 'mock';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kpi.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                        const SizedBox(height: 4),
                        Text(kpi.description, style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMock ? Colors.amber[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isMock ? Colors.amber[200]! : Colors.green[200]!),
                          ),
                          child: Text(
                            isMock ? l10n.estimatedBadge : l10n.liveDataBadge,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isMock ? Colors.amber[800] : Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${kpi.unit == '\$' ? '\$' : ''}${kpi.actual.toString()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('/ ${kpi.unit == '\$' ? '\$' : ''}${kpi.target.toString()} ${kpi.unit != '\$' ? kpi.unit : ''}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                      const SizedBox(height: 4),
                      Text(l10n.scoreLabel(kpi.score), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: themeColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (kpi.score.clamp(0, 100)) / 100.0,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
