import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';

class KpiOwnerView extends StatelessWidget {
  final KpiData data;

  const KpiOwnerView({super.key, required this.data});

  // ── Colour palette for each KPI card ─────────────────────────────────────
  static const List<Color> _cardColors = [
    Color(0xFF6366F1), // Indigo  – Attendance
    Color(0xFFEF4444), // Red     – Turnover
    Color(0xFF8B5CF6), // Violet  – Payroll
    Color(0xFFF59E0B), // Amber   – Expenses
    Color(0xFF10B981), // Emerald – Hiring
    Color(0xFF3B82F6), // Blue    – Performance
    Color(0xFFEC4899), // Pink    – Leave
    Color(0xFF14B8A6), // Teal    – Training
  ];

  static const List<IconData> _cardIcons = [
    Icons.people_alt_rounded,
    Icons.trending_down_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.receipt_long_rounded,
    Icons.work_outline_rounded,
    Icons.star_outline_rounded,
    Icons.event_available_rounded,
    Icons.school_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final kpis = data.ownerKpis;
    final avg = data.metrics.companyAverage;

    return Column(
      children: [
        // ── Overall Company Score Banner ──────────────────────────────────────
        _CompanyScoreBanner(average: avg, totalKpis: kpis.length),

        // ── KPI Cards Grid ───────────────────────────────────────────────────
        Expanded(
          child: kpis.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: kpis.length,
                  itemBuilder: (context, index) {
                    final color = _cardColors[index % _cardColors.length];
                    final icon = _cardIcons[index % _cardIcons.length];
                    return _OwnerKpiCard(
                      kpi: kpis[index],
                      color: color,
                      icon: icon,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Company Score Banner ────────────────────────────────────────────────────
class _CompanyScoreBanner extends StatelessWidget {
  final num average;
  final int totalKpis;

  const _CompanyScoreBanner({required this.average, required this.totalKpis});

  String _scoreLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (average >= 80) return l10n.scoreExcellent;
    if (average >= 60) return l10n.scoreGood;
    if (average >= 40) return l10n.scoreNeedsAttention;
    return l10n.scoreCritical;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: (average.clamp(0, 100)) / 100.0,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$average',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.companyHealthScore,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scoreLabel(context),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.kpisTrackedLiveData(totalKpis),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

// ── Individual KPI Card ─────────────────────────────────────────────────────
class _OwnerKpiCard extends StatelessWidget {
  final KpiItem kpi;
  final Color color;
  final IconData icon;

  const _OwnerKpiCard({
    required this.kpi,
    required this.color,
    required this.icon,
  });

  String _formatValue(num value, String unit) {
    if (unit == '\$') {
      if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
      return '\$${value.toStringAsFixed(0)}';
    }
    if (unit == '/ 5') return value.toStringAsFixed(2);
    if (unit == '%') return '${value.toStringAsFixed(1)}%';
    return value.toString();
  }

  Color get _scoreColor {
    final s = kpi.score.toDouble();
    if (s >= 80) return Colors.green;
    if (s >= 60) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = kpi.score.toDouble();
    if (s >= 80) return l10n.kpiOnTrack;
    if (s >= 60) return l10n.kpiModerate;
    return l10n.kpiAtRisk;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = (kpi.score.clamp(0, 100)) / 100.0;
    final extra = kpi.extra;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Title + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kpi.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kpi.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      l10n.liveDataBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Values row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Actual value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatValue(kpi.actual, kpi.unit),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (kpi.target != 0)
                        Text(
                          '${l10n.targetLabel}${_formatValue(kpi.target, kpi.unit)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                  // Score badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${kpi.score}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scoreLabel(context),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 7,
                ),
              ),
            ),

            // ── Extra breakdown (if available) ────────────────────────────────
            if (extra.isNotEmpty) _buildExtraChips(extra, color),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraChips(Map<String, dynamic> extra, Color color) {
    final chips = <Widget>[];
    extra.forEach((key, value) {
      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.noCompanyKpisFound,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noCompanyKpisDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
