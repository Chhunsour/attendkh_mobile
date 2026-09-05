import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/models/kpi_model.dart';
import 'package:attendkh/providers/kpi_provider.dart';
import 'package:attendkh/services/kpi_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';

class AdminKpisTab extends ConsumerStatefulWidget {
  const AdminKpisTab({super.key});

  @override
  ConsumerState<AdminKpisTab> createState() => _AdminKpisTabState();
}

class _AdminKpisTabState extends ConsumerState<AdminKpisTab> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(systemKpisProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return kpisAsync.when(
      data: (kpiData) {
        final attainment = kpiData.attainmentSummary;
        final allAssignments = kpiData.assignments;
        final filteredAssignments = allAssignments.where((goal) {
          if (_selectedStatus != 'all' && goal.status != _selectedStatus) {
            return false;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(systemKpisProvider);
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Executive Attainment Card ─────────────────────────────────
              _buildExecutiveSummaryCard(context, kpiData, attainment, isDark),

              const SizedBox(height: 16),

              // ── Filter Status Chips & Action Header ────────────────────────
              _buildFilterHeader(context, l10n, allAssignments.length),

              const SizedBox(height: 12),

              // ── Assigned Goals List ───────────────────────────────────────
              if (filteredAssignments.isEmpty)
                _buildEmptyState(context, l10n)
              else
                ...filteredAssignments.map(
                  (goal) => _buildGoalCard(context, goal, l10n, isDark),
                ),
            ],
          ),
        );
      },
      loading: () => Center(
        child: LoadingIndicator(message: l10n.loadingKpis),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text(
              '${l10n.errorLoadingKpis}$err',
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(systemKpisProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryCard(
    BuildContext context,
    KpiData kpiData,
    KpiAttainmentSummary? attainment,
    bool isDark,
  ) {
    final score = attainment?.overallAttainment ??
        kpiData.metrics.companyAverage.toDouble();
    final dist = attainment?.distribution ??
        KpiDistribution(onTrack: 0, moderate: 0, atRisk: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Score Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: (score.clamp(0, 100)) / 100.0,
                      strokeWidth: 6.5,
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
                          fontSize: 22,
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
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPANY ATTAINMENT',
                      style: TextStyle(
                        fontSize: 11,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${kpiData.assignments.length} total goals assigned across departments',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Distribution row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('On Track', '${dist.onTrack}',
                    const Color(0xFF34D399)),
                _buildDivider(),
                _buildStatColumn('Moderate', '${dist.moderate}',
                    const Color(0xFFFBBF24)),
                _buildDivider(),
                _buildStatColumn(
                    'At Risk', '${dist.atRisk}', const Color(0xFFF87171)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
      height: 24,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildFilterHeader(
    BuildContext context,
    AppLocalizations l10n,
    int totalCount,
  ) {
    final filters = ['all', 'pending', 'submitted', 'approved', 'completed'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.assignedGoals} ($totalCount)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: AppColors.primary,
              onPressed: () => ref.invalidate(systemKpisProvider),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary(context),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface(context),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border(context),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = status);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Employee & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  goal.employee?.fullName.isNotEmpty == true
                      ? goal.employee!.fullName[0].toUpperCase()
                      : 'E',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${goal.employee?.fullName ?? 'Employee'} • ${goal.employee?.departmentName ?? 'General'} • Weight: ${goal.weightPercentage.round()}%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  goal.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              goal.description!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Progress Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.actualValue} / ${goal.targetValue} ${goal.unit}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
              Text(
                '${progress.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _getProgressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress.clamp(0, 100)) / 100.0,
              backgroundColor: AppColors.grey200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEvaluateDialog(context, goal),
                icon: const Icon(Icons.rate_review_outlined, size: 15),
                label: Text(l10n.evaluateGoal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEvaluateDialog(BuildContext context, EmployeeKpiItem goal) {
    final l10n = AppLocalizations.of(context)!;
    final actualController =
        TextEditingController(text: goal.actualValue.toString());
    final notesController =
        TextEditingController(text: goal.managerNotes ?? '');
    String selectedStatus =
        goal.status == 'pending' ? 'approved' : goal.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${goal.title} (${goal.employee?.fullName ?? ''})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey500,
                    ),
                  ),
                  const Divider(height: 24),
                  if (goal.employeeNotes != null &&
                      goal.employeeNotes!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.employeeNotesLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.employeeNotes!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: actualController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText:
                                '${l10n.actualValueLabel} (${goal.unit})',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
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
                            if (val != null) {
                              setModalState(() => selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.managerNotesLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final actual =
                            num.tryParse(actualController.text.trim()) ?? 0;
                        try {
                          await KpiRepository.evaluateKpi(
                            goal.id,
                            actualValue: actual,
                            status: selectedStatus,
                            managerNotes: notesController.text.trim(),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.saveEvaluation,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.assignment_turned_in_outlined,
              size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          Text(
            l10n.noKpisFound,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assign measurable targets to employees from the web or mobile dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
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
