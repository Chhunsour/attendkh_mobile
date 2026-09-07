import 'package:flutter/material.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/models/kpi_model.dart';

class KpiSharedComponents {
  static Widget buildSummaryCard({
    required BuildContext context,
    required String title,
    required num score,
    required String subtitle,
    required Color color,
    required IconData icon,
    num? branchAverage,
    num? companyAverage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String ratingLabel;
    Color ratingColor;
    final l10n = AppLocalizations.of(context)!;
    if (score >= 85) {
      ratingLabel = l10n.performanceGradeExcellent;
      ratingColor = AppColors.success;
    } else if (score >= 70) {
      ratingLabel = l10n.scoreGood;
      ratingColor = const Color(0xFF3B82F6);
    } else if (score >= 50) {
      ratingLabel = l10n.performanceGradeAverage;
      ratingColor = AppColors.warning;
    } else {
      ratingLabel = l10n.performanceGradeNeedsAttention;
      ratingColor = AppColors.danger;
    }

    final Color cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);
    final Color iconBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEFF6FF);
    final Color iconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                                : const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.grey900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ratingColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Text(
                  ratingLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: ratingColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (branchAverage != null && branchAverage > 0) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 13,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Branch Avg: $branchAverage%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.grey300 : AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (kpis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.track_changes_outlined,
              size: 52,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noKpisFound,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final Color cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics ??
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: kpis.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        final isMock = kpi.type == 'mock';

        Color scoreColor;
        if (kpi.score >= 80) {
          scoreColor = AppColors.success;
        } else if (kpi.score >= 50) {
          scoreColor = AppColors.warning;
        } else {
          scoreColor = AppColors.danger;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
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
                        Text(
                          kpi.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.grey900,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (kpi.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            kpi.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey500,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isMock
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isMock
                                    ? l10n.estimatedBadge
                                    : l10n.liveDataBadge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.grey300
                                      : AppColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Builder(
                            builder: (_) {
                              final prefix = kpi.unit == '\$' ? '\$' : '';
                              return Text(
                                '$prefix${kpi.actual}',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.grey900,
                                ),
                              );
                            },
                          ),
                          Builder(
                            builder: (_) {
                              final prefix = kpi.unit == '\$' ? '\$' : '';
                              final suffix =
                                  kpi.unit != '\$' ? ' ${kpi.unit}' : '';
                              return Text(
                                ' / $prefix${kpi.target}$suffix',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${kpi.score}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (kpi.score.clamp(0, 100)) / 100.0,
                  backgroundColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
