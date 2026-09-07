import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/pages/hr/branch_payroll_settings_screen.dart';
import 'package:attendkh/pages/hr/formulas_screen.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/hr_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';

// ── Branches Tab ────────────────────────────────────────────────────────────
class BranchesTab extends ConsumerStatefulWidget {
  const BranchesTab({super.key});

  @override
  ConsumerState<BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends ConsumerState<BranchesTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortDesc = false;
  String? _filterActive;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    Future.microtask(() => ref.invalidate(branchesProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterActive != null) count++;
    if (_sortBy != 'name' || _sortDesc) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _filterActive = null;
      _sortBy = 'name';
      _sortDesc = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branchesAsync = ref.watch(branchesProvider);
    return Stack(
      children: [
        Column(
          children: [
            // Search Input + Filter Toggle
            Container(
              color: AppColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(
                              () => _searchQuery = val.trim().toLowerCase(),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary(context),
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.searchBranchesHint,
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey400,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: AppColors.grey200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter Toggle Button
                      InkWell(
                        onTap: () => setState(() => _showFilters = !_showFilters),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _showFilters || _activeFilterCount > 0
                                ? const Color(0xFF6366F1)
                                : AppColors.grey50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _showFilters || _activeFilterCount > 0
                                  ? const Color(0xFF6366F1)
                                  : AppColors.border(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: _showFilters || _activeFilterCount > 0
                                    ? Colors.white
                                    : AppColors.grey600,
                              ),
                              if (_activeFilterCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Collapsible Filter Drawer
                  if (_showFilters) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filters & Sorting',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_activeFilterCount > 0)
                                TextButton(
                                  onPressed: _clearFilters,
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: AppColors.danger,
                                  ),
                                  child: const Text('Reset All', style: TextStyle(fontSize: 11.5)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Status Filter Chips
                          const Text('Status', style: TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusChip(null, 'All'),
                              const SizedBox(width: 6),
                              _buildStatusChip('true', 'Active'),
                              const SizedBox(width: 6),
                              _buildStatusChip('false', 'Inactive'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Sort By
                          const Text('Sort By', style: TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildSortChip('name', false, 'Name A-Z'),
                              const SizedBox(width: 6),
                              _buildSortChip('name', true, 'Name Z-A'),
                              const SizedBox(width: 6),
                              _buildSortChip('headcount', true, 'Headcount High-Low'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grey200),
            // Content
            Expanded(
              child: branchesAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    if (_searchQuery.isNotEmpty) {
                      final name = item.name.toLowerCase();
                      final address = (item.address ?? '').toLowerCase();
                      final email = (item.email ?? '').toLowerCase();
                      if (!name.contains(_searchQuery) &&
                          !address.contains(_searchQuery) &&
                          !email.contains(_searchQuery)) {
                        return false;
                      }
                    }
                    final matchesActive =
                        _filterActive == null ||
                        (_filterActive == 'true' && (item.isActive ?? true)) ||
                        (_filterActive == 'false' && !(item.isActive ?? true));
                    return matchesActive;
                  }).toList();
                  filteredItems.sort((a, b) {
                    int cmp;
                    if (_sortBy == 'headcount') {
                      cmp = (a.employeesCount ?? 0).compareTo(
                        b.employeesCount ?? 0,
                      );
                    } else {
                      cmp = a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    }
                    return _sortDesc ? -cmp : cmp;
                  });

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(branchesProvider);
                      return await ref.read(branchesProvider.future);
                    },
                    child: filteredItems.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.corporate_fare_rounded,
                                        size: 48,
                                        color: AppColors.grey300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty || _activeFilterCount > 0
                                            ? 'No branches match your filters'
                                            : l10n.noBranchesFound,
                                        style: const TextStyle(
                                          color: AppColors.grey500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (_activeFilterCount > 0 || _searchQuery.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: _clearFilters,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6366F1),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Clear Filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _buildItem(context, ref, filteredItems[i]),
                          ),
                  );
                },
                loading: () => LoadingIndicator(message: l10n.loadingBranches),
                error: (e, _) => _errorWidget(ref, branchesProvider, l10n),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(100),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BranchFormDialog(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_business_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.addBranchBtn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, BranchData item) {
    final active = item.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Full width for Title & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? const Color(0xFF16A34A)
                                    : AppColors.grey500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (item.code != null && item.code!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.code!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.grey100),

          // Info Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                if (item.address != null && item.address!.isNotEmpty)
                  _buildMetaRow(Icons.place_outlined, item.address!),
                if (item.phone != null && item.phone!.isNotEmpty)
                  _buildMetaRow(Icons.phone_outlined, item.phone!),
                if (item.email != null && item.email!.isNotEmpty)
                  _buildMetaRow(Icons.mail_outline_rounded, item.email!),
                if (item.latitude != null && item.longitude != null)
                  _buildMetaRow(
                    Icons.gps_fixed_rounded,
                    'Coords: ${item.latitude!.toStringAsFixed(6)}, ${item.longitude!.toStringAsFixed(6)} (Radius: ${item.allowedRadiusMeters ?? 100}m)',
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.managerName != null
                          ? 'Manager: ${item.managerName}'
                          : 'No Manager assigned',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item.employeesCount ?? 0} Employees',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dedicated Bottom Actions Toolbar
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border(context).withAlpha(120)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: const Color(0xFF6366F1),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BranchFormDialog(branch: item),
                  ),
                ),
                _buildActionBtn(
                  icon: Icons.payments_outlined,
                  label: 'Payroll',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BranchPayrollSettingsScreen(
                          branchId: item.id,
                          branchName: item.name,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionBtn(
                  icon: Icons.menu_book_outlined,
                  label: 'Formulas',
                  color: const Color(0xFFF59E0B),
                  onTap: () async {
                    final s = await ref.read(
                      branchFormulasProvider(item.id).future,
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormulasScreen(settings: s),
                        ),
                      );
                    }
                  },
                ),
                _buildActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppColors.danger,
                  onTap: () => _deleteItem(context, ref, item.id, item.name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Warning Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  l10n.deleteBranchTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [TextSpan(text: l10n.deleteBranchConfirm(name))],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(hrRepositoryProvider).deleteBranch(id);

        ref.invalidate(branchesProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Branch deleted successfully"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _errorWidget(
    WidgetRef ref,
    ProviderBase provider,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.failedToLoadBranches,
            style: const TextStyle(fontSize: 14, color: AppColors.grey600),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? val, String label) {
    final isSelected = _filterActive == val;
    return InkWell(
      onTap: () => setState(() => _filterActive = val),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : AppColors.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey800,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String sortBy, bool desc, String label) {
    final isSelected = _sortBy == sortBy && _sortDesc == desc;
    return InkWell(
      onTap: () => setState(() {
        _sortBy = sortBy;
        _sortDesc = desc;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : AppColors.grey200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey800,
          ),
        ),
      ),
    );
  }
}

// ── Branch Form Dialog ────────────────────────────────────────────────────────
class BranchFormDialog extends ConsumerStatefulWidget {
  final BranchData? branch;
  const BranchFormDialog({super.key, this.branch});

  @override
  ConsumerState<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends ConsumerState<BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _radiusCtrl;
  late TextEditingController _mapUrlCtrl;
  int? _managerId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isResolvingMap = false;
  String? _mapSuccessMsg;
  String? _mapErrorMsg;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _addressCtrl = TextEditingController(text: b?.address ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');
    _latCtrl = TextEditingController(text: b?.latitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: b?.longitude?.toString() ?? '');
    _radiusCtrl = TextEditingController(
      text: b?.allowedRadiusMeters?.toString() ?? '100',
    );
    _mapUrlCtrl = TextEditingController();
    _managerId = b?.managerId;
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    _mapUrlCtrl.dispose();
    super.dispose();
  }

  Map<String, double>? _extractCoordsFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final directMatch = RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)\s*,\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$').firstMatch(trimmed);
    if (directMatch != null) {
      final parts = trimmed.split(',');
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final qMatch = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final centerMatch = RegExp(r'center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)', caseSensitive: false).firstMatch(trimmed);
    if (centerMatch != null) {
      final lat = double.tryParse(centerMatch.group(1)!);
      final lng = double.tryParse(centerMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final llMatch = RegExp(r'[?&](?:ll|daddr|saddr)=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (llMatch != null) {
      final lat = double.tryParse(llMatch.group(1)!);
      final lng = double.tryParse(llMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final placeMatch = RegExp(r'/place/(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (placeMatch != null) {
      final lat = double.tryParse(placeMatch.group(1)!);
      final lng = double.tryParse(placeMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    final embedMatch = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(trimmed);
    if (embedMatch != null) {
      final lat = double.tryParse(embedMatch.group(1)!);
      final lng = double.tryParse(embedMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    return null;
  }

  Future<void> _resolveMapUrl([String? urlOverride]) async {
    final text = (urlOverride ?? _mapUrlCtrl.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _mapSuccessMsg = null;
      _mapErrorMsg = null;
    });

    final local = _extractCoordsFromText(text);
    if (local != null) {
      setState(() {
        _latCtrl.text = local['latitude']!.toString();
        _lngCtrl.text = local['longitude']!.toString();
        _mapSuccessMsg = 'Coordinates extracted: ${local['latitude']!.toStringAsFixed(6)}, ${local['longitude']!.toStringAsFixed(6)}';
      });
      return;
    }

    setState(() => _isResolvingMap = true);
    try {
      final res = await ref.read(hrRepositoryProvider).resolveMapUrl(text);
      if (res != null && res['latitude'] != null && res['longitude'] != null) {
        setState(() {
          _latCtrl.text = res['latitude']!.toString();
          _lngCtrl.text = res['longitude']!.toString();
          _mapSuccessMsg = 'Coordinates extracted: ${res['latitude']!.toStringAsFixed(6)}, ${res['longitude']!.toStringAsFixed(6)}';
        });
      } else {
        setState(() {
          _mapErrorMsg = 'Could not extract coordinates from this link.';
        });
      }
    } catch (_) {
      setState(() {
        _mapErrorMsg = 'Network error resolving map link.';
      });
    } finally {
      setState(() => _isResolvingMap = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latCtrl.text = position.latitude.toString();
        _lngCtrl.text = position.longitude.toString();
        _mapSuccessMsg = 'GPS location set: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.branch == null) {
        await ref
            .read(hrRepositoryProvider)
            .createBranch(
              name: _nameCtrl.text,
              address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
              phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
              email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
              latitude: double.tryParse(_latCtrl.text),
              longitude: double.tryParse(_lngCtrl.text),
              allowedRadiusMeters: int.tryParse(_radiusCtrl.text),
              managerId: _managerId,
              isActive: _isActive,
            );
      } else {
        await ref
            .read(hrRepositoryProvider)
            .updateBranch(
              widget.branch!.id,
              name: _nameCtrl.text,
              address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
              phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
              email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
              latitude: double.tryParse(_latCtrl.text),
              longitude: double.tryParse(_lngCtrl.text),
              allowedRadiusMeters: int.tryParse(_radiusCtrl.text),
              managerId: _managerId,
              isActive: _isActive,
            );
      }
      ref.invalidate(branchesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.branch == null ? 'Create Branch' : 'Edit Branch',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Text(
                        'Configure office GPS and details',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.grey500,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Branch Name',
                          prefixIcon: Icon(
                            Icons.business_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(
                            Icons.place_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      employeesAsync.when(
                        data: (employees) {
                          final hasManager =
                              _managerId != null &&
                              employees.any((e) => e.userId == _managerId);
                          final initialManagerId = hasManager
                              ? _managerId
                              : null;
                          return DropdownButtonFormField<int>(
                            initialValue: initialManagerId,
                            decoration: const InputDecoration(
                              labelText: 'Branch Manager',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.grey400,
                                size: 20,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No Manager'),
                              ),
                              ...employees
                                  .where((e) => e.userId != null)
                                  .map(
                                    (e) => DropdownMenuItem<int>(
                                      value: e.userId,
                                      child: Text(e.name),
                                    ),
                                  ),
                            ],
                            onChanged: (val) =>
                                setState(() => _managerId = val),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading managers: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Geofence Section
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Geofence — GPS Clock-In Office Lock',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF14532D),
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Employees can only clock in within this boundary. Paste a Google Maps link or coordinates below, or use GPS if you are on-site.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF166534),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Option 1: Paste Google Maps URL (Auto-Calculate)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Paste Google Maps Link',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFF059669)),
                                            SizedBox(width: 3),
                                            Text(
                                              'Auto-Calculates',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _mapUrlCtrl,
                                          onChanged: (val) => _resolveMapUrl(val),
                                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                          decoration: InputDecoration(
                                            hintText: 'https://maps.app.goo.gl/... or 11.5564, 104.9282',
                                            hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(color: AppColors.primary),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: _isResolvingMap ? null : () => _resolveMapUrl(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isResolvingMap
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Text('Extract', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_mapSuccessMsg != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _mapSuccessMsg!,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_mapErrorMsg != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFDC2626)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _mapErrorMsg!,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'OR USE ON-SITE GPS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // GPS Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _getLocation,
                                icon: _isLoading
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
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                label: Text(
                                  _isLoading
                                      ? 'Getting GPS location...'
                                      : '📍 I am physically at this office right now — Detect GPS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),

                            // Show coordinates if set
                            if (_latCtrl.text.isNotEmpty ||
                                _lngCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Office Coordinates Lock:',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF14532D),
                                            ),
                                          ),
                                          Text(
                                            '${double.tryParse(_latCtrl.text)?.toStringAsFixed(6) ?? _latCtrl.text}, ${double.tryParse(_lngCtrl.text)?.toStringAsFixed(6) ?? _lngCtrl.text}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _latCtrl.clear();
                                          _lngCtrl.clear();
                                          _mapUrlCtrl.clear();
                                          _mapSuccessMsg = null;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Radius quick-pick + custom
                            const Text(
                              'Allowed Radius (meters from office)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...[50, 100, 200, 500].map((r) {
                                  final isSelected =
                                      _radiusCtrl.text == r.toString();
                                  return GestureDetector(
                                    onTap: () => setState(
                                      () => _radiusCtrl.text = r.toString(),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.grey300,
                                        ),
                                      ),
                                      child: Text(
                                        '${r}m',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.grey600,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _radiusCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Custom',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active toggle
                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Branch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const Text(
                                  'Inactive branches are hidden from new assignments',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
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
