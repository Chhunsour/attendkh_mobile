import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/company_rules_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class CompanyRulesScreen extends ConsumerStatefulWidget {
  const CompanyRulesScreen({super.key});

  @override
  ConsumerState<CompanyRulesScreen> createState() => _CompanyRulesScreenState();
}

class _CompanyRulesScreenState extends ConsumerState<CompanyRulesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(companyRulesProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            // ── AttendKH Gradient Hero Header ──
            _buildHeroHeader(context, isDark, l10n, rulesAsync.value?.length ?? 0),

            // ── Rules Body ──
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  final filtered = rules.where((r) {
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return r.title.toLowerCase().contains(q) ||
                        r.description.toLowerCase().contains(q);
                  }).toList();

                  final Color cardBg =
                      isDark ? const Color(0xFF242424) : Colors.white;
                  final Color cardBorder = isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFE2E8F0);

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(companyRulesProvider),
                    color: AppColors.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Search Bar ──
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.02,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (val) =>
                                        setState(() => _searchQuery = val.trim()),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.grey900,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: l10n.searchRulesHint,
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? AppColors.grey500
                                            : AppColors.grey400,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: isDark
                                            ? AppColors.grey400
                                            : AppColors.grey400,
                                        size: 20,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                color: isDark
                                                    ? AppColors.grey400
                                                    : AppColors.grey400,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() => _searchQuery = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ── Section Header ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.regulationsAndPolicies,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.grey900,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF3B82F6)
                                                    .withValues(alpha: 0.3)
                                                : const Color(0xFFBFDBFE),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '${filtered.length} ${l10n.guidelinesCount}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // ── Lazy Virtualized Rules List ──
                        if (filtered.isEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off_rounded,
                                      size: 44,
                                      color: AppColors.grey300,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? '${l10n.noRulesMatching} "$_searchQuery"'
                                          : l10n.noCompanyRules,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.grey400
                                            : AppColors.grey600,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                            sliver: SliverList.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final rule = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRuleCard(
                                    index + 1,
                                    rule.title,
                                    rule.description,
                                    isDark,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => Center(
                  child: LoadingIndicator(message: l10n.loading),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(companyRulesProvider),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
    int totalRules,
  ) {
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
              22,
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
                            l10n.companyRules,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.companyRulesSubtitle,
                            style: const TextStyle(
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
                        ref.invalidate(companyRulesProvider);
                      },
                    ),
                  ],
                ),
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

  Widget _buildRuleCard(
    int index,
    String title,
    String description,
    bool isDark,
  ) {
    final indexStr = index.toString().padLeft(2, '0');

    final Color cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final Color cardBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                        : const Color(0xFFBFDBFE),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '#$indexStr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
