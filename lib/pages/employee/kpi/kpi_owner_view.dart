import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/models/kpi_model.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/providers/kpi_provider.dart';
import 'package:attendkh/services/kpi_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';

class KpiOwnerView extends ConsumerStatefulWidget {
  final KpiData data;

  const KpiOwnerView({super.key, required this.data});

  @override
  ConsumerState<KpiOwnerView> createState() => _KpiOwnerViewState();
}

class _KpiOwnerViewState extends ConsumerState<KpiOwnerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attainment = widget.data.attainmentSummary;
    final assignments = widget.data.assignments;
    final templates = widget.data.templates;
    final ownerKpis = widget.data.ownerKpis;

    return Column(
      children: [
        // ── Top Executive Score Card ─────────────────────────────────────────
        _buildExecutiveHeader(context, attainment, isDark),

        // ── Modern Pill TabBar ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.grey500,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            tabs: [
              const Tab(text: 'Attainment'),
              Tab(text: '${l10n.assignedGoals} (${assignments.length})'),
              Tab(text: '${l10n.kpiTemplates} (${templates.length})'),
            ],
          ),
        ),

        // ── TabBar Views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Attainment & Matrix
              _buildOverviewTab(context, attainment, ownerKpis, isDark),

              // Tab 2: Assigned Goals & Evaluations
              _buildAssignmentsTab(context, assignments, l10n, isDark),

              // Tab 3: Template Library
              _buildTemplatesTab(context, templates, l10n, isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ── 1. Top Executive Score Header ──────────────────────────────────────────
  Widget _buildExecutiveHeader(
    BuildContext context,
    KpiAttainmentSummary? attainment,
    bool isDark,
  ) {
    final score = attainment?.overallAttainment ??
        widget.data.metrics.companyAverage.toDouble();
    final dist = attainment?.distribution ??
        KpiDistribution(onTrack: 0, moderate: 0, atRisk: 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF4338CA), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Radial Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: (score.clamp(0, 100)) / 100.0,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.round()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPANY KPI ATTAINMENT',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      score >= 80
                          ? 'Strategic Goals On Track'
                          : score >= 50
                              ? 'Goals in Progress'
                              : 'Attention Required',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.data.assignments.length} goals across ${attainment?.departmentAttainment.length ?? 0} departments',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Distribution Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('On Track', '${dist.onTrack}',
                    const Color(0xFF34D399)),
                _buildDivider(),
                _buildStatPill('Moderate', '${dist.moderate}',
                    const Color(0xFFFBBF24)),
                _buildDivider(),
                _buildStatPill(
                    'At Risk', '${dist.atRisk}', const Color(0xFFF87171)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quick Action Buttons matching Web Header
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignGoalSheet(context),
                  icon: const Icon(Icons.add_task_rounded, size: 15),
                  label: const Text(
                    'Assign Goal',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4338CA),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTemplateSheet(context),
                  icon: const Icon(Icons.library_add_rounded, size: 15),
                  label: const Text(
                    'New Template',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ── 2. Overview Tab (Department, Leaderboard & Operations) ──────────────────
  Widget _buildOverviewTab(
    BuildContext context,
    KpiAttainmentSummary? attainment,
    List<KpiItem> ownerKpis,
    bool isDark,
  ) {
    final deptList = attainment?.departmentAttainment ?? [];
    final topList = attainment?.topPerformers ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Department Attainment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Department Attainment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${deptList.length} depts',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deptList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No department goals assigned yet.',
                      style: TextStyle(fontSize: 12, color: AppColors.grey500),
                    ),
                  ),
                )
              else
                ...deptList.map((dept) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dept.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${dept.score}% (${dept.goalsCount} goals)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _getProgressColor(dept.score),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (dept.score.clamp(0, 100)) / 100.0,
                              minHeight: 6,
                              backgroundColor: AppColors.grey200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(dept.score),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Top Goal Achievers Leaderboard
        if (topList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      'Top Goal Achievers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...topList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final emp = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          child: Text(
                            '#${idx + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${emp.department} • ${emp.position}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${emp.score}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Company Operations Metrics
        Text(
          'COMPANY OPERATIONS METRICS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 8),
        ...ownerKpis.map((kpi) => _buildOperationalKpiCard(context, kpi)),
      ],
    );
  }

  Widget _buildOperationalKpiCard(BuildContext context, KpiItem kpi) {
    final score = kpi.score;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kpi.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _getProgressColor(score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${kpi.unit == '\$' ? '\$' : ''}${kpi.actual.toString()}${kpi.unit != '\$' ? ' ${kpi.unit}' : ''}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.clamp(0, 100)) / 100.0,
              minHeight: 5,
              backgroundColor: AppColors.grey200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(score)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Assigned Goals & Evaluations Tab ─────────────────────────────────────
  Widget _buildAssignmentsTab(
    BuildContext context,
    List<EmployeeKpiItem> assignments,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final filtered = assignments.where((g) {
      if (_selectedStatus != 'all' && g.status != _selectedStatus) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = g.employee?.fullName.toLowerCase() ?? '';
        final title = g.title.toLowerCase();
        return name.contains(q) || title.contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Search & Add Goal Row
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search employee or goal...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _showAssignGoalSheet(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'all',
              'pending',
              'submitted',
              'approved',
              'completed',
            ].map((status) {
              final isSel = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : AppColors.textPrimary(context),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface(context),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSel
                          ? AppColors.primary
                          : AppColors.border(context),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedStatus = status);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(Icons.assignment_turned_in_outlined,
                    size: 44, color: AppColors.grey400),
                SizedBox(height: 10),
                Text(
                  'No assigned goals found',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          )
        else
          ...filtered.map((goal) => _buildGoalCard(context, goal, l10n, isDark)),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    EmployeeKpiItem goal,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final progress = goal.progressPercent;
    final statusColor = _getStatusColor(goal.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  goal.employee?.fullName.isNotEmpty == true
                      ? goal.employee!.fullName[0].toUpperCase()
                      : 'E',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${goal.employee?.fullName ?? 'Employee'} • Weight: ${goal.weightPercentage.round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  goal.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.actualValue} / ${goal.targetValue} ${goal.unit}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
              Text(
                '${progress.round()}%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress.clamp(0, 100)) / 100.0,
              minHeight: 5,
              backgroundColor: AppColors.grey200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEvaluateSheet(context, goal),
                icon: const Icon(Icons.rate_review_outlined, size: 14),
                label: Text(l10n.evaluateGoal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDeleteGoal(context, goal),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.danger),
                tooltip: 'Delete Goal',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4. Templates Tab ────────────────────────────────────────────────────────
  Widget _buildTemplatesTab(
    BuildContext context,
    List<KpiTemplateItem> templates,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Create Template Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KPI Template Repository',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Text(
                  'Reusable goals & performance standards',
                  style: TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showTemplateSheet(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Create',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (templates.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No KPI templates created yet.',
                style: TextStyle(fontSize: 13, color: AppColors.grey500),
              ),
            ),
          )
        else
          ...templates.map((tpl) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tpl.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Target: ${tpl.targetValue ?? '100'} ${tpl.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () =>
                                  _confirmDeleteTemplate(context, tpl),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppColors.danger),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tpl.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tpl.description != null &&
                        tpl.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tpl.description!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showAssignGoalSheet(context, template: tpl),
                        icon: const Icon(Icons.add_task_rounded, size: 14),
                        label: const Text('Assign This Goal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // ── 5. Modal BottomSheet: Assign Goal ──────────────────────────────────────
  void _showAssignGoalSheet(BuildContext context,
      {KpiTemplateItem? template}) {
    final titleCtrl = TextEditingController(text: template?.title ?? '');
    final targetCtrl =
        TextEditingController(text: template?.targetValue?.toString() ?? '100');
    final unitCtrl = TextEditingController(text: template?.unit ?? 'Units');
    final weightCtrl = TextEditingController(text: '20');
    final descCtrl =
        TextEditingController(text: template?.description ?? '');

    String targetType = 'employee'; // 'employee' or 'department'
    int? selectedEmployeeId;
    int? selectedDepartmentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final employeesAsync = ref.watch(allEmployeesProvider);
            final departmentsAsync = ref.watch(departmentsProvider);

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Assign KPI Goal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Assignment Scope Toggle
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Specific Employee'),
                                selected: targetType == 'employee',
                                onSelected: (val) {
                                  if (val) {
                                    setSheetState(() => targetType = 'employee');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Entire Department'),
                                selected: targetType == 'department',
                                onSelected: (val) {
                                  if (val) {
                                    setSheetState(
                                        () => targetType = 'department');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Employee or Department Dropdown
                        if (targetType == 'employee')
                          employeesAsync.when(
                            data: (list) {
                              return DropdownButtonFormField<int>(
                                initialValue: selectedEmployeeId,
                                decoration: InputDecoration(
                                  labelText: 'Select Employee *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: list.map((emp) {
                                  return DropdownMenuItem<int>(
                                    value: emp.id,
                                    child: Text(
                                      '${emp.fullName ?? emp.name} (${emp.department ?? 'General'})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setSheetState(
                                    () => selectedEmployeeId = val),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Error loading employees: $e'),
                          )
                        else
                          departmentsAsync.when(
                            data: (depts) {
                              return DropdownButtonFormField<int>(
                                initialValue: selectedDepartmentId,
                                decoration: InputDecoration(
                                  labelText: 'Select Department *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: depts.map((d) {
                                  return DropdownMenuItem<int>(
                                    value: d.id,
                                    child: Text(d.name),
                                  );
                                }).toList(),
                                onChanged: (val) => setSheetState(
                                    () => selectedDepartmentId = val),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('Error loading departments: $e'),
                          ),

                        const SizedBox(height: 12),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            labelText: 'Goal Title *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: targetCtrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Target Value *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: unitCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Unit (e.g. %, \$)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Weight Percentage (%)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description / Targets Context',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a goal title'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }
                              final targetVal =
                                  num.tryParse(targetCtrl.text.trim()) ?? 100;
                              final weightVal =
                                  num.tryParse(weightCtrl.text.trim()) ?? 20;

                              final payload = <String, dynamic>{
                                'target_type': targetType,
                                'employee_id': selectedEmployeeId,
                                'department_id': selectedDepartmentId,
                                'template_id': template?.id,
                                'title': title,
                                'target_value': targetVal,
                                'unit': unitCtrl.text.trim().isEmpty
                                    ? 'Units'
                                    : unitCtrl.text.trim(),
                                'weight_percentage': weightVal,
                                'description': descCtrl.text.trim(),
                              };

                              try {
                                await KpiRepository.assignKpi(payload);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ref.invalidate(systemKpisProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Goal assigned successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error assigning goal: $e'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm Assignment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── 6. Modal BottomSheet: Create KPI Template ──────────────────────────────
  void _showTemplateSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');
    final unitCtrl = TextEditingController(text: '%');
    final descCtrl = TextEditingController();
    String scopeType = 'individual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Create KPI Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Template Title *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: scopeType,
                      decoration: InputDecoration(
                        labelText: 'Scope Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'individual', child: Text('Individual Role')),
                        DropdownMenuItem(
                            value: 'departmental',
                            child: Text('Departmental')),
                        DropdownMenuItem(
                            value: 'branch', child: Text('Branch')),
                        DropdownMenuItem(
                            value: 'company', child: Text('Company-Wide')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => scopeType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Target Value',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: 'Unit (e.g. %, \$)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description / Standards',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a template title'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          final payload = <String, dynamic>{
                            'title': title,
                            'type': scopeType,
                            'target_value':
                                num.tryParse(targetCtrl.text.trim()) ?? 100,
                            'unit': unitCtrl.text.trim().isEmpty
                                ? 'Units'
                                : unitCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                          };

                          try {
                            await KpiRepository.createTemplate(payload);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(systemKpisProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✅ KPI Template saved to library'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save KPI Template',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 7. Evaluate Goal Modal ──────────────────────────────────────────────────
  void _showEvaluateSheet(BuildContext context, EmployeeKpiItem goal) {
    final l10n = AppLocalizations.of(context)!;
    final actualCtrl =
        TextEditingController(text: goal.actualValue.toString());
    final notesCtrl = TextEditingController(text: goal.managerNotes ?? '');
    String status = goal.status == 'pending' ? 'approved' : goal.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.evaluateGoal,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  Text(
                    '${goal.title} (${goal.employee?.fullName ?? ''})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                    ),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: actualCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${l10n.actualValueLabel} (${goal.unit})',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.managerNotesLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final actual =
                            num.tryParse(actualCtrl.text.trim()) ?? 0;
                        try {
                          await KpiRepository.evaluateKpi(
                            goal.id,
                            actualValue: actual,
                            status: status,
                            managerNotes: notesCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ref.invalidate(systemKpisProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ KPI Evaluation saved'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.saveEvaluation,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 8. Delete Confirmations ─────────────────────────────────────────────────
  void _confirmDeleteGoal(BuildContext context, EmployeeKpiItem goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal Assignment?'),
        content: Text('Are you sure you want to remove "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await KpiRepository.deleteAssignment(goal.id);
                ref.invalidate(systemKpisProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Goal assignment deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting goal: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTemplate(BuildContext context, KpiTemplateItem tpl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete KPI Template?'),
        content: Text(
            'Are you sure you want to delete template "${tpl.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await KpiRepository.deleteTemplate(tpl.id);
                ref.invalidate(systemKpisProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Template deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting template: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'approved':
        return const Color(0xFF3B82F6);
      case 'submitted':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  Color _getProgressColor(num progress) {
    if (progress >= 80) return AppColors.success;
    if (progress >= 50) return AppColors.warning;
    return AppColors.danger;
  }
}
