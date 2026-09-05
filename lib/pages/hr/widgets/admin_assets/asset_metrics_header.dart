import 'package:flutter/material.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';

class AssetMetricsHeader extends StatelessWidget {
  final int totalAssets;
  final int assignedAssets;
  final int availableAssets;
  final double totalValue;

  const AssetMetricsHeader({
    super.key,
    required this.totalAssets,
    required this.assignedAssets,
    required this.availableAssets,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 400;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      Icons.inventory_2,
                      Colors.indigo,
                      totalAssets.toString(),
                      l10n.totalAssetsLabel,
                    ),
                  ),
                  if (wide) const SizedBox(width: 10),
                  if (wide)
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        Icons.person,
                        AppColors.info,
                        assignedAssets.toString(),
                        l10n.assignedLabel,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      Icons.laptop,
                      AppColors.success,
                      availableAssets.toString(),
                      l10n.statusLabel,
                    ),
                  ),
                  if (wide) const SizedBox(width: 10),
                  if (wide)
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        Icons.attach_money,
                        Colors.orange,
                        '\$${totalValue.toStringAsFixed(totalValue == totalValue.roundToDouble() ? 0 : 2)}',
                        l10n.totalValueLabel,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
