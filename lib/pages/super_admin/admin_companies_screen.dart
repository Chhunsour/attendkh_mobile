import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
// removed
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_companies_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminCompaniesProvider = FutureProvider.autoDispose<List<AdminCompany>>((
  ref,
) {
  return AdminCompaniesRepository().getCompanies();
});

String _getLogoUrl(String logo) {
  if (logo.startsWith('http://') || logo.startsWith('https://')) {
    return logo;
  }
  var cleanPath = logo;
  if (cleanPath.startsWith('/storage/')) {
    cleanPath = cleanPath.substring('/storage/'.length);
  } else if (cleanPath.startsWith('storage/')) {
    cleanPath = cleanPath.substring('storage/'.length);
  }
  if (cleanPath.startsWith('/')) {
    cleanPath = cleanPath.substring(1);
  }
  return '${DioClient.storageUrl}/$cleanPath';
}

class CompanyLogoImage extends StatelessWidget {
  final String logo;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackIcon;

  const CompanyLogoImage({
    super.key,
    required this.logo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (logo.isEmpty) {
      return fallbackIcon ??
          const Icon(Icons.business_rounded, color: AppColors.grey400);
    }

    final primaryUrl = _getLogoUrl(logo);

    var cleanPath = logo;
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      cleanPath = '';
    } else {
      if (cleanPath.startsWith('/storage/')) {
        cleanPath = cleanPath.substring('/storage/'.length);
      } else if (cleanPath.startsWith('storage/')) {
        cleanPath = cleanPath.substring('storage/'.length);
      }
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
    }

    final secondaryUrl = cleanPath.isNotEmpty
        ? '${DioClient.instance.options.baseUrl.replaceAll('/api', '/storage/')}$cleanPath'
        : null;

    return CachedNetworkImage(
      imageUrl: primaryUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        if (secondaryUrl != null && secondaryUrl != primaryUrl) {
          return CachedNetworkImage(
            imageUrl: secondaryUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) =>
                fallbackIcon ??
                const Icon(Icons.business_rounded, color: AppColors.grey400),
          );
        }
        return fallbackIcon ??
            const Icon(Icons.business_rounded, color: AppColors.grey400);
      },
    );
  }
}

class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  ConsumerState<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends ConsumerState<AdminCompaniesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(adminCompaniesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.adminCompaniesTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminCompaniesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(context, ref),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_business_rounded, size: 20),
        label: const Text(
          'Add Company',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminCompaniesProvider),
        child: companiesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(context, err, ref, l10n),
          data: (companies) => _buildContent(context, ref, companies, l10n),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object err,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadCompanies,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminCompaniesProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<AdminCompany> companies,
    AppLocalizations l10n,
  ) {
    final activeCount = companies.where((c) => c.status == 'active').length;
    final suspendedCount = companies.where((c) => c.status != 'active').length;

    final filtered = companies.where((c) {
      if (_statusFilter == 'active' && c.status != 'active') return false;
      if (_statusFilter == 'suspended' && c.status == 'active') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = c.name.toLowerCase().contains(q);
        final emailMatch = c.email?.toLowerCase().contains(q) ?? false;
        final phoneMatch = c.phone?.toLowerCase().contains(q) ?? false;
        return nameMatch || emailMatch || phoneMatch;
      }
      return true;
    }).toList();

    return CustomScrollView(
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
                // ── Overview Summary Cards ──
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Tenants',
                        value: '${companies.length}',
                        icon: Icons.business_rounded,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Active',
                        value: '$activeCount',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Suspended',
                        value: '$suspendedCount',
                        icon: Icons.pause_circle_filled_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Search Field ──
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Search companies by name or email...',
                      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Status Filter Chips ──
                Row(
                  children: [
                    _buildFilterChip('All (${companies.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active ($activeCount)', 'active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Suspended ($suspendedCount)', 'suspended'),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Lazy Virtualized Company List ──
        if (filtered.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center_outlined, size: 48, color: AppColors.grey300),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty ? 'No companies matching "$_searchQuery"' : l10n.noCompaniesYet,
                      style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final company = filtered[index];
                return _buildCompanyCard(context, ref, company, l10n);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
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
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
    AppLocalizations l10n,
  ) {
    final isActive = company.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFEEF2FF) : AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: (company.logo != null && company.logo!.isNotEmpty)
                    ? CompanyLogoImage(
                        logo: company.logo!,
                        fit: BoxFit.cover,
                        fallbackIcon: Icon(
                          Icons.business_rounded,
                          color: isActive ? const Color(0xFF6366F1) : AppColors.danger,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.business_rounded,
                        color: isActive ? const Color(0xFF6366F1) : AppColors.danger,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (company.email != null && company.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        company.email!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: isActive ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? l10n.statusActive : l10n.statusSuspended,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: AppColors.textPrimary(context),
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                position: PopupMenuPosition.under,
                offset: const Offset(0, 4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.grey700,
                    size: 18,
                  ),
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showCreateEditDialog(context, ref, company: company);
                  } else if (action == 'suspend') {
                    _confirmSuspend(context, ref, company);
                  } else if (action == 'activate') {
                    _confirmActivate(context, ref, company);
                  } else if (action == 'stats') {
                    _showStats(context, company);
                  } else if (action == 'delete') {
                    _confirmDelete(context, ref, company);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    height: 42,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6366F1)),
                        const SizedBox(width: 10),
                        Text(l10n.actionEdit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'stats',
                    height: 42,
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF0EA5E9)),
                        const SizedBox(width: 10),
                        Text(l10n.actionStats, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (isActive)
                    PopupMenuItem(
                      value: 'suspend',
                      height: 42,
                      child: Row(
                        children: [
                          const Icon(Icons.block_rounded, size: 18, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Text(l10n.actionSuspend, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  if (!isActive)
                    PopupMenuItem(
                      value: 'activate',
                      height: 42,
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                          const SizedBox(width: 10),
                          Text(l10n.actionActivate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    height: 42,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Text(l10n.actionDelete, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSuspend(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.suspendCompanyTitle),
        content: Text(l10n.suspendCompanyContent(company.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.actionSuspend),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminCompaniesRepository().suspendCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.companySuspendedSuccess(company.name)),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmActivate(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.activateCompanyTitle),
        content: Text(l10n.activateCompanyContent(company.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.actionActivate),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminCompaniesRepository().activateCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.companyActivatedSuccess(company.name)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminCompany company,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteCompanyTitle),
        content: Text(l10n.deleteCompanyContent(company.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await AdminCompaniesRepository().deleteCompany(company.id);
        ref.invalidate(adminCompaniesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.companyDeletedSuccess(company.name)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showStats(BuildContext context, AdminCompany company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CompanyStatsSheet(company: company),
    );
  }

  void _showCreateEditDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminCompany? company,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CompanyFormSheet(company: company, ref: ref),
    );
  }
}

class _CompanyFormSheet extends ConsumerStatefulWidget {
  final AdminCompany? company;
  final WidgetRef ref;

  const _CompanyFormSheet({this.company, required this.ref});

  @override
  ConsumerState<_CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends ConsumerState<_CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _timezoneCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _adminNameCtrl;
  late final TextEditingController _adminEmailCtrl;
  late final TextEditingController _adminPasswordCtrl;
  late final TextEditingController _businessTypeCtrl;
  late final TextEditingController _companySizeCtrl;
  late final TextEditingController _vattinCtrl;
  late final TextEditingController _telegramBotTokenCtrl;
  late final TextEditingController _telegramChatIdCtrl;
  late final TextEditingController _mapUrlCtrl;
  String _selectedTimezone = 'Asia/Phnom_Penh';
  String _selectedCurrency = 'USD';
  String _status = 'active';
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  bool _isParsingMapUrl = false;
  bool _isVatRegistered = false;
  bool _telegramEnabled = false;
  bool _isTestingTelegram = false;
  Map<String, dynamic>? _telegramTestStatus;
  double? _latitude;
  double? _longitude;
  File? _logoFile;
  final _picker = ImagePicker();

  List<Map<String, String>> _socialMediaList = [];

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    final sm = c?.socialMedia;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _timezoneCtrl = TextEditingController(
      text: c?.timezone ?? 'Asia/Phnom_Penh',
    );
    _currencyCtrl = TextEditingController(text: c?.currency ?? 'USD');
    _selectedTimezone = c?.timezone ?? 'Asia/Phnom_Penh';
    _selectedCurrency = c?.currency ?? 'USD';
    _adminNameCtrl = TextEditingController();
    _adminEmailCtrl = TextEditingController();
    _adminPasswordCtrl = TextEditingController();
    _businessTypeCtrl = TextEditingController(text: c?.businessType ?? '');
    _companySizeCtrl = TextEditingController(text: c?.companySize ?? '');
    _vattinCtrl = TextEditingController(text: c?.vattin ?? '');
    _telegramBotTokenCtrl = TextEditingController(
      text: c?.telegramBotToken ?? '',
    );
    _telegramChatIdCtrl = TextEditingController(text: c?.telegramChatId ?? '');
    _mapUrlCtrl = TextEditingController(text: c?.mapUrl ?? '');
    _isVatRegistered = c?.isVatRegistered ?? false;
    _telegramEnabled = c?.telegramEnabled ?? false;
    _latitude = c?.latitude;
    _longitude = c?.longitude;
    _status = c?.status ?? 'active';

    if (sm != null) {
      _socialMediaList = sm.map((e) {
        if (e is Map) {
          return {
            'platform': (e['platform'] ?? '').toString(),
            'url': (e['url'] ?? '').toString(),
          };
        }
        return {'platform': '', 'url': ''};
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _timezoneCtrl.dispose();
    _currencyCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _businessTypeCtrl.dispose();
    _companySizeCtrl.dispose();
    _vattinCtrl.dispose();
    _telegramBotTokenCtrl.dispose();
    _telegramChatIdCtrl.dispose();
    _mapUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // ignore: deprecated_member_use
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        address = address
            .split(', ')
            .where((part) => part.trim().isNotEmpty && part != 'null')
            .join(', ');
        setState(() {
          _addressCtrl.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _parseMapUrl(String url) {
    setState(() => _isParsingMapUrl = true);
    if (url.trim().isEmpty) {
      setState(() => _isParsingMapUrl = false);
      return;
    }

    // 1. Extract place name from URL
    final placeNameMatch = RegExp(r'/place/([^/@]+)').firstMatch(url);
    if (placeNameMatch != null && placeNameMatch.group(1) != null) {
      try {
        final rawName = Uri.decodeComponent(
          placeNameMatch.group(1)!.replaceAll('+', ' '),
        );
        if (rawName.isNotEmpty &&
            !RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(rawName)) {
          _addressCtrl.text = rawName;
        }
      } catch (_) {}
    }

    // 2. Extract lat/lng from URL
    final atMatch =
        RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url) ??
        RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(url) ??
        RegExp(
          r'[?&](?:q|ll|query)=(-?\d+\.\d+),(-?\d+\.\d+)',
        ).firstMatch(url) ??
        RegExp(r'^\s*(-?\d+\.\d+)[,\s]+(-?\d+\.\d+)\s*$').firstMatch(url);

    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lon = double.tryParse(atMatch.group(2)!);
      if (lat != null) _latitude = lat;
      if (lon != null) _longitude = lon;
    }

    setState(() => _isParsingMapUrl = false);
  }

  Future<void> _testTelegram() async {
    final token = _telegramBotTokenCtrl.text.trim();
    final chatId = _telegramChatIdCtrl.text.trim();
    if (token.isEmpty || chatId.isEmpty) return;

    setState(() {
      _isTestingTelegram = true;
      _telegramTestStatus = null;
    });

    try {
      final dio = DioClient.instance;
      final response = await dio.post(
        '/admin/companies/test-telegram',
        data: {'telegram_bot_token': token, 'telegram_chat_id': chatId},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        setState(() {
          _telegramTestStatus = {
            'success': true,
            'message': data['message'] ?? 'Test message sent successfully',
          };
        });
      } else {
        setState(() {
          _telegramTestStatus = {
            'success': false,
            'message': data['message'] ?? 'Failed to send test message',
          };
        });
      }
    } catch (e) {
      setState(() {
        _telegramTestStatus = {
          'success': false,
          'message': 'Network error: $e',
        };
      });
    } finally {
      setState(() => _isTestingTelegram = false);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final compressedFile = await ImageCompressor.compressToWebp(picked.path);
      setState(() => _logoFile = compressedFile);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'timezone': _selectedTimezone,
        'currency': _selectedCurrency,
        'social_media': _socialMediaList,
        'status': _status,
        'is_vat_registered': _isVatRegistered,
        'vattin': _isVatRegistered ? _vattinCtrl.text.trim() : null,
        'business_type': _businessTypeCtrl.text.trim(),
        'company_size': _companySizeCtrl.text.trim(),
        'telegram_enabled': _telegramEnabled,
        'telegram_bot_token': _telegramBotTokenCtrl.text.trim(),
        'telegram_chat_id': _telegramChatIdCtrl.text.trim(),
        'map_url': _mapUrlCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (_adminNameCtrl.text.trim().isNotEmpty) {
        data['admin_name'] = _adminNameCtrl.text.trim();
      }
      if (_adminEmailCtrl.text.trim().isNotEmpty) {
        data['admin_email'] = _adminEmailCtrl.text.trim();
      }
      if (_adminPasswordCtrl.text.trim().isNotEmpty) {
        data['admin_password'] = _adminPasswordCtrl.text.trim();
      }

      final repo = AdminCompaniesRepository();
      final logoPath = _logoFile?.path;
      AdminCompanyCreationResult? createRes;
      if (_isEditing) {
        await repo.updateCompany(widget.company!.id, data, logoPath: logoPath);
      } else {
        createRes = await repo.createCompany(data, logoPath: logoPath);
      }

      widget.ref.invalidate(adminCompaniesProvider);

      if (mounted) {
        Navigator.pop(context);
        if (createRes != null && createRes.ownerEmail != null) {
          final companyName = data['name']?.toString() ?? 'Company';
          final email = createRes.ownerEmail!;
          final pass = createRes.ownerPassword ?? 'Password123!';
          _showCompanyCreatedDialog(
            context: context,
            companyName: companyName,
            email: email,
            password: pass,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? l10n.companyUpdatedSuccess
                    : l10n.companyCreatedSuccess,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? l10n.editCompanyTitle : l10n.createCompanyTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Company Name + Email (row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildField(
                            l10n.companyNameLabel,
                            _nameCtrl,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? l10n.fieldRequired
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            l10n.emailLabel,
                            _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? l10n.fieldRequired
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Business Type + Company Size (row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            'Type of Business',
                            _businessTypeCtrl,
                            [
                              'Technology & IT',
                              'Retail & Wholesale',
                              'Garment & Manufacturing',
                              'Food & Beverage / Hospitality',
                              'Construction & Real Estate',
                              'Banking & Financial Services',
                              'Logistics & Transportation',
                              'Education & Healthcare',
                              'Professional Services',
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            'Total Staff (Company Size)',
                            _companySizeCtrl,
                            [
                              '1-10 Staff (Micro)',
                              '11-50 Staff (Small)',
                              '51-100 Staff (Medium)',
                              '101-500 Staff (Large)',
                              '500+ Staff (Enterprise)',
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Owner Account Credentials (styled box — primary color like web)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.companyOwnerAccountTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? l10n.companyOwnerEditDesc
                                : l10n.companyOwnerCreateDesc,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildField(l10n.ownerNameLabel, _adminNameCtrl),
                          const SizedBox(height: 10),
                          _buildField(
                            l10n.ownerLoginEmailLabel,
                            _adminEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          _buildField(
                            _isEditing
                                ? l10n.newPasswordOptionalLabel
                                : l10n.ownerPasswordLabel,
                            _adminPasswordCtrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Phone Number
                    _buildField(
                      l10n.phoneLabel,
                      _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    // VAT Taxpayer Status — amber section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x0AFFA000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33FFA000)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VAT Taxpayer Status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF856404),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Is this company registered for VAT?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF856404),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isVatRegistered,
                                onChanged: (val) =>
                                    setState(() => _isVatRegistered = val),
                                activeThumbColor: const Color(0xFFFFA000),
                              ),
                            ],
                          ),
                          if (_isVatRegistered) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0x33FFA000)),
                            const SizedBox(height: 10),
                            _buildField('VAT TIN Number', _vattinCtrl),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Google Maps URL + Address + GPS display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Google Maps URL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _mapUrlCtrl,
                          onChanged: _parseMapUrl,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            hintText: 'Paste Google Maps link...',
                            suffixIcon: _isParsingMapUrl
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.map_outlined,
                                    size: 20,
                                    color: AppColors.grey400,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Address with Get Location button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.addressLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isLoadingLocation
                                  ? null
                                  : _getCurrentLocation,
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                              label: Text(
                                _isLoadingLocation
                                    ? l10n.gettingLocation
                                    : l10n.getLocation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_latitude != null || _longitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x0A10B981),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x3310B981),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'GPS: Lat ${_latitude?.toStringAsFixed(6) ?? "N/A"}, Lng ${_longitude?.toStringAsFixed(6) ?? "N/A"}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Timezone + Currency (row)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.timezoneLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    [
                                      'Asia/Phnom_Penh',
                                      'UTC',
                                      'America/New_York',
                                      'Europe/London',
                                      'Asia/Tokyo',
                                    ].contains(_selectedTimezone)
                                    ? _selectedTimezone
                                    : 'Asia/Phnom_Penh',
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Asia/Phnom_Penh',
                                    child: Text(
                                      'Asia/Phnom_Penh',
                                      style: TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UTC',
                                    child: Text(
                                      'UTC',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'America/New_York',
                                    child: Text(
                                      'America/New_York',
                                      style: TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Europe/London',
                                    child: Text(
                                      'Europe/London',
                                      style: TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Asia/Tokyo',
                                    child: Text(
                                      'Asia/Tokyo',
                                      style: TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedTimezone = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currencyLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    [
                                      'USD',
                                      'EUR',
                                      'GBP',
                                      'JPY',
                                    ].contains(_selectedCurrency)
                                    ? _selectedCurrency
                                    : 'USD',
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.backgroundLight,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'USD',
                                    child: Text(
                                      'USD (\$)',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'EUR',
                                    child: Text(
                                      'EUR (€)',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'GBP',
                                    child: Text(
                                      'GBP (£)',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'JPY',
                                    child: Text(
                                      'JPY (¥)',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCurrency = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Social Media section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border(context)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.backgroundLight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.socialMediaLinksTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _socialMediaList.add({
                                      'platform': '',
                                      'url': '',
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(
                                  l10n.actionAdd,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_socialMediaList.isEmpty)
                            Text(
                              l10n.noSocialMediaLinks,
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 13,
                              ),
                            ),
                          ...List.generate(_socialMediaList.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue:
                                          _socialMediaList[index]['platform'],
                                      decoration: InputDecoration(
                                        hintText: l10n.platformLabel,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.grey200,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 0,
                                            ),
                                      ),
                                      onChanged: (val) =>
                                          _socialMediaList[index]['platform'] =
                                              val,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue:
                                          _socialMediaList[index]['url'],
                                      decoration: InputDecoration(
                                        hintText: l10n.urlLabel,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.grey200,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 0,
                                            ),
                                      ),
                                      onChanged: (val) =>
                                          _socialMediaList[index]['url'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: AppColors.danger,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _socialMediaList.removeAt(index);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Logo upload (before Telegram — matches web)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.companyLogoTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickLogo,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.grey200,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.backgroundLight,
                            ),
                            child: _logoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _logoFile!,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : (widget.company?.logo != null &&
                                      widget.company!.logo!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CompanyLogoImage(
                                          logo: widget.company!.logo!,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          fallbackIcon: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.business_rounded,
                                                color: AppColors.grey400,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.tapToChangeLogo,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.grey500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: AppColors.textPrimary(context),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  l10n.tapToChangeLogo,
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary(context),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.cloud_upload_outlined,
                                        color: AppColors.grey400,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.tapToUploadLogo,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Telegram Bot Notifications — sky section (after Logo — matches web)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x0A0EA5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x330EA5E9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.send_rounded,
                                        color: AppColors.textPrimary(context),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Telegram Bot Notifications',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0C4A6E),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Configure bot for attendance & alerts',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0EA5E9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _telegramEnabled,
                                onChanged: (val) =>
                                    setState(() => _telegramEnabled = val),
                                activeThumbColor: const Color(0xFF0EA5E9),
                              ),
                            ],
                          ),
                          if (_telegramEnabled) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0x330EA5E9)),
                            const SizedBox(height: 12),
                            _buildField('Bot Token', _telegramBotTokenCtrl),
                            const SizedBox(height: 4),
                            const Text(
                              'Obtain from @BotFather on Telegram',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildField('Chat ID', _telegramChatIdCtrl),
                            const SizedBox(height: 4),
                            const Text(
                              'Target group or channel ID where bot is an Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Test Telegram Connection button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (_isTestingTelegram ||
                                            _telegramBotTokenCtrl.text
                                                .trim()
                                                .isEmpty ||
                                            _telegramChatIdCtrl.text
                                                .trim()
                                                .isEmpty)
                                        ? null
                                        : _testTelegram,
                                    icon: _isTestingTelegram
                                        ? SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      _isTestingTelegram
                                          ? 'Testing...'
                                          : 'Test Connection',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0EA5E9),
                                      disabledBackgroundColor: const Color(
                                        0xFF0EA5E9,
                                      ).withAlpha(80),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Will send a test message to the Chat ID',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_telegramTestStatus != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _telegramTestStatus!['success']
                                      ? const Color(0x1A10B981)
                                      : const Color(0x1AF43F5E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _telegramTestStatus!['success']
                                        ? const Color(0x3310B981)
                                        : const Color(0x33F43F5E),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _telegramTestStatus!['success']
                                          ? Icons.check_circle_rounded
                                          : Icons.error_outline_rounded,
                                      size: 16,
                                      color: _telegramTestStatus!['success']
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF43F5E),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _telegramTestStatus!['message'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _telegramTestStatus!['success']
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFF9F1239),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Status dropdown (after Telegram — matches web)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.statusLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border(context)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text(l10n.statusActive),
                                ),
                                DropdownMenuItem(
                                  value: 'suspended',
                                  child: Text(l10n.statusSuspended),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? l10n.btnUpdateCompany
                                    : l10n.btnCreateCompany,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController ctrl,
    List<String> suggestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
            suffixIcon: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: suggestions
                                .map(
                                  (s) => ListTile(
                                    title: Text(
                                      s,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    trailing: ctrl.text == s
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          )
                                        : null,
                                    onTap: () {
                                      ctrl.text = s;
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey400,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyStatsSheet extends StatefulWidget {
  final AdminCompany company;
  const _CompanyStatsSheet({required this.company});

  @override
  State<_CompanyStatsSheet> createState() => _CompanyStatsSheetState();
}

class _CompanyStatsSheetState extends State<_CompanyStatsSheet> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminCompaniesRepository().getCompanyStats(
        widget.company.id,
      );
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companyStatsTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      widget.company.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.grey500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadStats();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  )
                : _stats.isEmpty
                ? Center(
                    child: Text(
                      l10n.noStatsAvailable,
                      style: const TextStyle(color: AppColors.grey400),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _stats.entries.map((e) {
                        final value = e.value.toString();
                        final label = e.key
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' ');
                        return Container(
                          width: (MediaQuery.of(context).size.width - 52) / 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

void _showCompanyCreatedDialog({
  required BuildContext context,
  required String companyName,
  required String email,
  required String password,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _CompanyCreatedSuccessDialog(
      companyName: companyName,
      email: email,
      password: password,
    ),
  );
}

class _CompanyCreatedSuccessDialog extends StatefulWidget {
  final String companyName;
  final String email;
  final String password;

  const _CompanyCreatedSuccessDialog({
    required this.companyName,
    required this.email,
    required this.password,
  });

  @override
  State<_CompanyCreatedSuccessDialog> createState() =>
      _CompanyCreatedSuccessDialogState();
}

class _CompanyCreatedSuccessDialogState
    extends State<_CompanyCreatedSuccessDialog> {
  bool _copiedEmail = false;
  bool _copiedPassword = false;
  bool _copiedAll = false;

  void _copy(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (type == 'Email') _copiedEmail = true;
      if (type == 'Password') _copiedPassword = true;
      if (type == 'Credentials') _copiedAll = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.grey900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.companyCreatedAlertTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.ownerCredentialsGenerated(widget.companyName),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // Credentials Card Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.ownerEmailTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey500,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copy(widget.email, 'Email'),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _copiedEmail ? Icons.check : Icons.copy_rounded,
                                size: 13,
                                color: _copiedEmail
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _copiedEmail ? l10n.copied : l10n.copy,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _copiedEmail
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.grey200),

                  // Password Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.ownerPasswordTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey500,
                          letterSpacing: 0.8,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copy(widget.password, 'Password'),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _copiedPassword
                                    ? Icons.check
                                    : Icons.copy_rounded,
                                size: 13,
                                color: _copiedPassword
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _copiedPassword ? l10n.copied : l10n.copy,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _copiedPassword
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    widget.password,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(
                      'Email: ${widget.email}\nPassword: ${widget.password}',
                      'Credentials',
                    ),
                    icon: Icon(
                      _copiedAll ? Icons.check : Icons.share_rounded,
                      size: 16,
                    ),
                    label: Text(_copiedAll ? l10n.copiedAll : l10n.copyAll),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.grey300),
                      foregroundColor: AppColors.grey800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
