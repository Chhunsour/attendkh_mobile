import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/providers/kpi_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

import 'kpi/kpi_employee_view.dart';
import 'kpi/kpi_manager_view.dart';
import 'kpi/kpi_owner_view.dart';
import 'kpi/kpi_super_admin_view.dart';

class KpiScreen extends ConsumerStatefulWidget {
  const KpiScreen({super.key});

  @override
  ConsumerState<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends ConsumerState<KpiScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _tabCount = 1;

  void _initTabs(KpiData data) {
    final isSuperAdmin = data.userRole == 'super_admin';
    final isOwner =
        data.userRole == 'company_owner' || data.userRole == 'company_admin';
    final isManager = data.userRole == 'branch_manager';

    int newTabCount = 1;
    if (!isSuperAdmin && !isOwner) {
      if (isManager) newTabCount = 2;
    }

    if (_tabController == null || _tabCount != newTabCount) {
      _tabCount = newTabCount;
      _tabController?.dispose();
      _tabController =
          TabController(length: _tabCount, vsync: this, initialIndex: 0);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kpisAsync = ref.watch(systemKpisProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: kpisAsync.when(
        data: (data) {
          _initTabs(data);

          final isSuperAdmin = data.userRole == 'super_admin';
          final isOwner =
              data.userRole == 'company_owner' || data.userRole == 'company_admin';
          final isManager = data.userRole == 'branch_manager';
          final showTabs = !isSuperAdmin && !isOwner && isManager;

          final title = isSuperAdmin ? l10n.platformHealth : l10n.performanceKpis;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Column(
              children: [
                // ── AttendKH Gradient Hero Header ──
                _buildHeroHeader(
                  context,
                  isDark,
                  title: title,
                  showTabs: showTabs,
                  l10n: l10n,
                ),

                // ── KPI Body ──
                Expanded(
                  child: isSuperAdmin
                      ? KpiSuperAdminView(data: data)
                      : isOwner
                          ? KpiOwnerView(data: data)
                          : showTabs
                              ? TabBarView(
                                  controller: _tabController,
                                  children: [
                                    KpiEmployeeView(data: data),
                                    KpiManagerView(data: data),
                                  ],
                                )
                              : KpiEmployeeView(data: data),
                ),
              ],
            ),
          );
        },
        loading: () => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Column(
            children: [
              _buildHeroHeader(
                context,
                isDark,
                title: l10n.performanceKpis,
                showTabs: false,
                l10n: l10n,
              ),
              const Expanded(
                child: Center(
                  child: LoadingIndicator(message: 'Loading KPIs...'),
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Column(
            children: [
              _buildHeroHeader(
                context,
                isDark,
                title: l10n.performanceKpis,
                showTabs: false,
                l10n: l10n,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 44,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load KPIs: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(systemKpisProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient Hero Header matching Dashboard & Leave Page ──
  Widget _buildHeroHeader(
    BuildContext context,
    bool isDark, {
    required String title,
    required bool showTabs,
    required AppLocalizations l10n,
  }) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient rings
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              showTabs ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Row
                Row(
                  children: [
                    _heroIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Track metrics, attendance & milestones',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _heroIconButton(
                      Icons.refresh_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.invalidate(systemKpisProvider);
                      },
                    ),
                  ],
                ),

                // Glass Segmented Tab Switcher (only if multiple tabs)
                if (showTabs && _tabController != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.primary,
                      unselectedLabelColor:
                          Colors.white.withValues(alpha: 0.82),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      tabs: [
                        Tab(text: l10n.myPerf),
                        Tab(text: l10n.team),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}
