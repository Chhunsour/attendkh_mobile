import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/assets_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_assign_sheet.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_card.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_create_edit_sheet.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_history_sheet.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_metrics_header.dart';

class AdminAssetsScreen extends ConsumerStatefulWidget {
  const AdminAssetsScreen({super.key});

  @override
  ConsumerState<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends ConsumerState<AdminAssetsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAsset(AssetData asset) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAssetTitle),
        content: Text(l10n.deleteAssetConfirm(asset.name, asset.assetCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AssetsRepository().deleteAsset(asset.id);
        ref.invalidate(assetsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.assetDeletedSuccess),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _returnAsset(AssetData asset) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.returnAssetTitle),
        content: Text(l10n.returnAssetConfirm(asset.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.returnBtn),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AssetsRepository().returnAsset(asset.id);
        ref.invalidate(assetsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.assetReturnedSuccess),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.companyAssetsTitle,
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
            onPressed: () => ref.invalidate(assetsProvider),
          ),
        ],
      ),
      body: assetsAsync.when(
        data: (items) {
          // Compute summary stats
          final totalAssets = items.length;
          final assignedAssets =
              items.where((a) => a.status == 'assigned').length;
          final availableAssets =
              items.where((a) => a.status == 'available').length;
          final totalValue =
              items.fold<double>(0, (sum, a) => sum + a.displayValue);

          // Filter items dynamically
          final q = _searchQuery.trim().toLowerCase();
          final categories = [
            'all',
            ...items
                .map((a) => a.category)
                .whereType<String>()
                .where((c) => c.isNotEmpty)
                .toSet()
          ];
          final filteredItems = items.where((a) {
            final matchesQuery = q.isEmpty ||
                a.assetCode.toLowerCase().contains(q) ||
                a.name.toLowerCase().contains(q) ||
                (a.serialNumber != null &&
                    a.serialNumber!.toLowerCase().contains(q)) ||
                (a.model != null && a.model!.toLowerCase().contains(q));
            final matchesStatus = _statusFilter == 'all' ||
                a.status.toLowerCase() == _statusFilter.toLowerCase();
            final matchesCategory = _categoryFilter == 'all' ||
                (a.category ?? '').toLowerCase() ==
                    _categoryFilter.toLowerCase();
            return matchesQuery && matchesStatus && matchesCategory;
          }).toList();

          return items.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.grey50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAssetsFound,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.addFirstAssetDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => AssetCreateEditSheet.show(
                            context: context,
                            onSaved: () => ref.invalidate(assetsProvider),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            l10n.addAssetBtn,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Summary Cards ──────────────────────────────────
                    AssetMetricsHeader(
                      totalAssets: totalAssets,
                      assignedAssets: assignedAssets,
                      availableAssets: availableAssets,
                      totalValue: totalValue,
                    ),

                    // ── Search & Filter Controls ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search code, name, serial, model...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey400,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.border(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Category dropdown
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _categoryFilter,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: categories.map((cat) {
                                        return DropdownMenuItem(
                                          value: cat,
                                          child: Text(
                                            cat == 'all'
                                                ? 'All Categories'
                                                : cat,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _categoryFilter = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status pill selector
                              Expanded(
                                flex: 6,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      'all',
                                      'available',
                                      'assigned',
                                      'maintenance',
                                      'retired',
                                    ].map((status) {
                                      final isSelected = _statusFilter == status;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(
                                            status == 'all'
                                                ? 'All'
                                                : status[0].toUpperCase() +
                                                    status.substring(1),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.grey700,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          backgroundColor:
                                              AppColors.surface(context),
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.border(context),
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() => _statusFilter = status);
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Asset List ─────────────────────────────────────
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noAssetsFound,
                                style: const TextStyle(color: AppColors.grey500),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isTablet = constraints.maxWidth > 600;
                                final itemCount = isTablet
                                    ? (filteredItems.length / 2).ceil()
                                    : filteredItems.length;

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                                  itemCount: itemCount,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    if (!isTablet) {
                                      final asset = filteredItems[i];
                                      return AssetCard(
                                        asset: asset,
                                        onAssign: () => AssetAssignSheet.show(
                                          context: context,
                                          asset: asset,
                                          onAssigned: () =>
                                              ref.invalidate(assetsProvider),
                                        ),
                                        onReturn: () => _returnAsset(asset),
                                        onEdit: () => AssetCreateEditSheet.show(
                                          context: context,
                                          asset: asset,
                                          onSaved: () =>
                                              ref.invalidate(assetsProvider),
                                        ),
                                        onHistory: () => AssetHistorySheet.show(
                                          context: context,
                                          assetId: asset.id,
                                          assetName: asset.name,
                                        ),
                                        onDelete: () => _deleteAsset(asset),
                                      );
                                    }

                                    final firstItem = filteredItems[i * 2];
                                    final hasSecond =
                                        i * 2 + 1 < filteredItems.length;

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AssetCard(
                                            asset: firstItem,
                                            onAssign: () =>
                                                AssetAssignSheet.show(
                                              context: context,
                                              asset: firstItem,
                                              onAssigned: () =>
                                                  ref.invalidate(assetsProvider),
                                            ),
                                            onReturn: () =>
                                                _returnAsset(firstItem),
                                            onEdit: () =>
                                                AssetCreateEditSheet.show(
                                              context: context,
                                              asset: firstItem,
                                              onSaved: () =>
                                                  ref.invalidate(assetsProvider),
                                            ),
                                            onHistory: () =>
                                                AssetHistorySheet.show(
                                              context: context,
                                              assetId: firstItem.id,
                                              assetName: firstItem.name,
                                            ),
                                            onDelete: () =>
                                                _deleteAsset(firstItem),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        if (hasSecond)
                                          Expanded(
                                            child: AssetCard(
                                              asset: filteredItems[i * 2 + 1],
                                              onAssign: () =>
                                                  AssetAssignSheet.show(
                                                context: context,
                                                asset: filteredItems[i * 2 + 1],
                                                onAssigned: () => ref.invalidate(
                                                    assetsProvider),
                                              ),
                                              onReturn: () => _returnAsset(
                                                  filteredItems[i * 2 + 1]),
                                              onEdit: () =>
                                                  AssetCreateEditSheet.show(
                                                context: context,
                                                asset: filteredItems[i * 2 + 1],
                                                onSaved: () => ref.invalidate(
                                                    assetsProvider),
                                              ),
                                              onHistory: () =>
                                                  AssetHistorySheet.show(
                                                context: context,
                                                assetId:
                                                    filteredItems[i * 2 + 1].id,
                                                assetName:
                                                    filteredItems[i * 2 + 1].name,
                                              ),
                                              onDelete: () => _deleteAsset(
                                                  filteredItems[i * 2 + 1]),
                                            ),
                                          )
                                        else
                                          const Expanded(child: SizedBox()),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
        },
        loading: () => const LoadingIndicator(message: 'Loading assets...'),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(assetsProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AssetCreateEditSheet.show(
          context: context,
          onSaved: () => ref.invalidate(assetsProvider),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}