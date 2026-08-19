import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'branch_payroll_settings_screen.dart';
import 'formulas_screen.dart';

class HrStructureScreen extends ConsumerStatefulWidget {
  const HrStructureScreen({super.key});

  @override
  ConsumerState<HrStructureScreen> createState() => _HrStructureScreenState();
}

class _HrStructureScreenState extends ConsumerState<HrStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.hrStructureTitle,
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
            onPressed: () {
              ref.invalidate(branchesProvider);
              ref.invalidate(departmentsProvider);
              ref.invalidate(positionsProvider);
              ref.invalidate(teamsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.textPrimary(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  icon: const Icon(Icons.corporate_fare_rounded, size: 18),
                  text: l10n.tabBranches,
                ),
                Tab(
                  icon: const Icon(Icons.apartment_rounded, size: 18),
                  text: l10n.tabDepts,
                ),
                Tab(
                  icon: const Icon(Icons.badge_rounded, size: 18),
                  text: l10n.tabPositions,
                ),
                Tab(
                  icon: const Icon(Icons.groups_rounded, size: 18),
                  text: l10n.tabTeams,
                ),
                Tab(
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  text: l10n.tabOrgChart,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey200),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _BranchesTab(),
                _DepartmentsTab(),
                _PositionsTab(),
                _TeamsTab(),
                _OrgChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branches Tab ────────────────────────────────────────────────────────────
class _BranchesTab extends ConsumerStatefulWidget {
  const _BranchesTab();

  @override
  ConsumerState<_BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends ConsumerState<_BranchesTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortDesc = false;
  String? _filterActive;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branchesAsync = ref.watch(branchesProvider);
    return Stack(
      children: [
        Column(
          children: [
            // Search Input + Sort
            Container(
              color: AppColors.textPrimary(context),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
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
                                    decoration: BoxDecoration(
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'name' && !_sortDesc) {
                          _sortDesc = true;
                        } else if (_sortBy == 'name') {
                          _sortBy = 'headcount';
                          _sortDesc = false;
                        } else if (_sortBy == 'headcount' && !_sortDesc) {
                          _sortDesc = true;
                        } else {
                          _sortBy = 'name';
                          _sortDesc = false;
                        }
                      });
                    },
                    child: Container(
                      height: 46,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'headcount'
                                ? Icons.people_rounded
                                : Icons.sort_by_alpha_rounded,
                            size: 18,
                            color: AppColors.grey600,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _sortDesc
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Active Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _filterActive,
                        hint: Text(
                          'All',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.grey500,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'true',
                            child: Text(
                              'Active',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'false',
                            child: Text(
                              'Inactive',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _filterActive = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.grey200),
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
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: _buildEmptyState(
                                  context,
                                  isFiltered:
                                      _searchQuery.isNotEmpty ||
                                      _filterActive != null,
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
                  builder: (_) => const _BranchFormDialog(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_business_rounded,
                        color: AppColors.textPrimary(context),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        l10n.addBranchBtn,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
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

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              isFiltered ? l10n.noBranchesFound : l10n.noBranchesAvailable,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered ? l10n.noBranchesFoundDesc : l10n.addFirstBranchDesc,
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, BranchData item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
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
                              color: (item.isActive ?? true)
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (item.isActive ?? true) ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: (item.isActive ?? true)
                                    ? const Color(0xFF16A34A)
                                    : AppColors.grey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _BranchFormDialog(branch: item),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: Colors.teal,
                      ),
                      onPressed: () {
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
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: () async {
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
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: () =>
                          _deleteItem(context, ref, item.id, item.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.grey100),
          ),

          // Info Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                const SizedBox(height: 10),
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
        ],
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

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
                          padding: EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey),
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
            l10n.failedToLoadBranches, // generic fallback
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
}

// ── Branch Form Dialog ────────────────────────────────────────────────────────
class _BranchFormDialog extends ConsumerStatefulWidget {
  final BranchData? branch;
  const _BranchFormDialog({this.branch});

  @override
  ConsumerState<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends ConsumerState<_BranchFormDialog> {
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

    // 1. Direct "11.5564, 104.9282"
    final directMatch = RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?)\s*,\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$').firstMatch(trimmed);
    if (directMatch != null) {
      final parts = trimmed.split(',');
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 2. @11.5564,104.9282
    final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 3. ?q=11.5564,104.9282
    final qMatch = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 4. center=11.5564%2C104.9282
    final centerMatch = RegExp(r'center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)', caseSensitive: false).firstMatch(trimmed);
    if (centerMatch != null) {
      final lat = double.tryParse(centerMatch.group(1)!);
      final lng = double.tryParse(centerMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 5. ll= or daddr= or saddr=
    final llMatch = RegExp(r'[?&](?:ll|daddr|saddr)=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (llMatch != null) {
      final lat = double.tryParse(llMatch.group(1)!);
      final lng = double.tryParse(llMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 6. /place/11.5564,104.9282
    final placeMatch = RegExp(r'/place/(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(trimmed);
    if (placeMatch != null) {
      final lat = double.tryParse(placeMatch.group(1)!);
      final lng = double.tryParse(placeMatch.group(2)!);
      if (lat != null && lng != null) return {'latitude': lat, 'longitude': lng};
    }

    // 7. !3d11.5564!4d104.9282
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

    // 1. Client-side regex check first
    final local = _extractCoordsFromText(text);
    if (local != null) {
      setState(() {
        _latCtrl.text = local['latitude']!.toString();
        _lngCtrl.text = local['longitude']!.toString();
        _mapSuccessMsg = 'Coordinates extracted: ${local['latitude']!.toStringAsFixed(6)}, ${local['longitude']!.toStringAsFixed(6)}';
      });
      return;
    }

    // 2. Server resolver for shortened URLs (maps.app.goo.gl, etc.)
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
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                SizedBox(width: 12),
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
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
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
                            SizedBox(height: 14),

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
                                          Icon(Icons.link_rounded, size: 14, color: AppColors.primary),
                                          SizedBox(width: 4),
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
                                    : Icon(
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
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(
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
                          SizedBox(width: 8),
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
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? SizedBox(
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

// ── Departments Tab ─────────────────────────────────────────────────────────
class _DepartmentsTab extends ConsumerStatefulWidget {
  const _DepartmentsTab();

  @override
  ConsumerState<_DepartmentsTab> createState() => _DepartmentsTabState();
}

class _DepartmentsTabState extends ConsumerState<_DepartmentsTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  int? _filterBranchId;
  String _sortBy = 'name';
  bool _sortDesc = false;
  String? _filterActive; // null = all, 'true' = active, 'false' = inactive

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deptsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Search and Filters Bar
            Container(
              color: AppColors.textPrimary(context),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Search
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
                          hintText: 'Search depts...',
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
                                    decoration: BoxDecoration(
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
                  // Sort Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'name' && !_sortDesc) {
                          _sortDesc = true;
                        } else if (_sortBy == 'name') {
                          _sortBy = 'headcount';
                          _sortDesc = false;
                        } else if (_sortBy == 'headcount' && !_sortDesc) {
                          _sortDesc = true;
                        } else {
                          _sortBy = 'name';
                          _sortDesc = false;
                        }
                      });
                    },
                    child: Container(
                      height: 46,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'headcount'
                                ? Icons.people_rounded
                                : Icons.sort_by_alpha_rounded,
                            size: 18,
                            color: AppColors.grey600,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _sortDesc
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Branch Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: branchesAsync.maybeWhen(
                        data: (branches) => DropdownButton<int?>(
                          value: _filterBranchId,
                          hint: Text(
                            l10n.allBranchesLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.grey500,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                l10n.allBranchesLabel,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            ...branches.map(
                              (b) => DropdownMenuItem<int?>(
                                value: b.id,
                                child: Text(
                                  b.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterBranchId = val),
                        ),
                        orElse: () => Text(l10n.loadingLabel),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Active Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _filterActive,
                        hint: Text(
                          'All',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.grey500,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'true',
                            child: Text(
                              'Active',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'false',
                            child: Text(
                              'Inactive',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _filterActive = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Divider(height: 1, color: AppColors.grey200),
            // Content List
            Expanded(
              child: deptsAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        item.name.toLowerCase().contains(_searchQuery);
                    final matchesBranch =
                        _filterBranchId == null ||
                        item.branchId == _filterBranchId;
                    final matchesActive =
                        _filterActive == null ||
                        (_filterActive == 'true' && (item.isActive ?? true)) ||
                        (_filterActive == 'false' && !(item.isActive ?? true));
                    return matchesSearch && matchesBranch && matchesActive;
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
                      ref.invalidate(departmentsProvider);
                      return await ref.read(departmentsProvider.future);
                    },
                    child: filteredItems.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: _buildEmptyState(
                                  context,
                                  isFiltered:
                                      _searchQuery.isNotEmpty ||
                                      _filterBranchId != null,
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
                loading: () => LoadingIndicator(message: l10n.loadingDepts),
                error: (e, _) => _errorWidget(ref, departmentsProvider, l10n),
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
                  builder: (_) => const _DepartmentFormDialog(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        l10n.addDeptBtn,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
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

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.corporate_fare_rounded,
                size: 36,
                color: AppColors.info,
              ),
            ),
            SizedBox(height: 16),
            Text(
              isFiltered ? l10n.noBranchesFound : l10n.noDeptsFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered ? l10n.noBranchesFoundDesc : l10n.addFirstDeptDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, DepartmentData item) {
    final active = item.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.corporate_fare_rounded,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
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
                              color: active
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? const Color(0xFF16A34A)
                                    : AppColors.grey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _DepartmentFormDialog(department: item),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: () =>
                          _deleteItem(context, ref, item.id, item.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.grey100),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (item.branchName != null && item.branchName!.isNotEmpty)
                  _buildMetaRow(
                    Icons.place_outlined,
                    'Branch: ${item.branchName!}',
                  ),
                if (item.parentName != null && item.parentName!.isNotEmpty)
                  _buildMetaRow(
                    Icons.account_tree_outlined,
                    'Parent Dept: ${item.parentName!}',
                  ),
                if (item.managerName != null && item.managerName!.isNotEmpty)
                  _buildMetaRow(
                    Icons.person_outline_rounded,
                    'Manager: ${item.managerName!}',
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
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
        ],
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
                /// Delete Icon
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
                  l10n.deleteDeptTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [TextSpan(text: l10n.deleteDeptConfirm(name))],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey),
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
        await ref.read(hrRepositoryProvider).deleteDepartment(id);

        ref.invalidate(departmentsProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Department deleted successfully"),
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
            l10n.failedToLoadDepts,
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
}

// ── Positions Tab ───────────────────────────────────────────────────────────
class _PositionsTab extends ConsumerStatefulWidget {
  const _PositionsTab();

  @override
  ConsumerState<_PositionsTab> createState() => _PositionsTabState();
}

class _PositionsTabState extends ConsumerState<_PositionsTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  int? _filterDeptId;
  String _sortBy = 'name';
  bool _sortDesc = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _getLevelColor(String? level) {
    if (level == null) return AppColors.grey500;
    switch (level) {
      case 'C-Level':
      case 'VP':
      case 'Director':
        return Colors.purple;
      case 'Manager':
        return Colors.blue;
      case 'Lead':
      case 'Senior':
        return Colors.teal;
      case 'Mid-Level':
        return const Color(0xFF10B981);
      case 'Junior':
      default:
        return AppColors.grey600;
    }
  }

  Color _getLevelBg(String? level) {
    if (level == null) return AppColors.grey100;
    switch (level) {
      case 'C-Level':
      case 'VP':
      case 'Director':
        return const Color(0xFFF3E8FF);
      case 'Manager':
        return const Color(0xFFDBEAFE);
      case 'Lead':
      case 'Senior':
        return const Color(0xFFCCFBF1);
      case 'Mid-Level':
        return const Color(0xFFD1FAE5);
      case 'Junior':
      default:
        return AppColors.grey100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final posAsync = ref.watch(positionsProvider);
    final deptsAsync = ref.watch(departmentsProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Search and Filters Bar
            Container(
              color: AppColors.textPrimary(context),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Search
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
                          hintText: 'Search roles...',
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
                                    decoration: BoxDecoration(
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
                  // Sort Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'name' && !_sortDesc) {
                          _sortDesc = true;
                        } else if (_sortBy == 'name') {
                          _sortBy = 'headcount';
                          _sortDesc = false;
                        } else if (_sortBy == 'headcount' && !_sortDesc) {
                          _sortDesc = true;
                        } else {
                          _sortBy = 'name';
                          _sortDesc = false;
                        }
                      });
                    },
                    child: Container(
                      height: 46,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'headcount'
                                ? Icons.people_rounded
                                : Icons.sort_by_alpha_rounded,
                            size: 18,
                            color: AppColors.grey600,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _sortDesc
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Dept Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: deptsAsync.maybeWhen(
                        data: (depts) => DropdownButton<int?>(
                          value: _filterDeptId,
                          hint: Text(
                            l10n.allDepartmentsLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.grey500,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                l10n.allDeptsLabel,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            ...depts.map(
                              (d) => DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(
                                  d.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterDeptId = val),
                        ),
                        orElse: () => Text(l10n.loadingLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Divider(height: 1, color: AppColors.grey200),
            // Content
            Expanded(
              child: posAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        item.name.toLowerCase().contains(_searchQuery);
                    final matchesDept =
                        _filterDeptId == null ||
                        item.departmentId == _filterDeptId;
                    return matchesSearch && matchesDept;
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

                  return filteredItems.isEmpty
                      ? _buildEmptyState(
                          context,
                          isFiltered:
                              _searchQuery.isNotEmpty || _filterDeptId != null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _buildItem(context, ref, filteredItems[i]),
                        );
                },
                loading: () => LoadingIndicator(message: l10n.loadingRoles),
                error: (e, _) => _errorWidget(ref, positionsProvider, l10n),
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
                  builder: (_) => const _PositionFormDialog(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 8),
                      Text(
                        l10n.addRoleBtn,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
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

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 36,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: 16),
            Text(
              isFiltered ? l10n.noBranchesFound : l10n.noRolesFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered ? l10n.noBranchesFoundDesc : l10n.addFirstRoleDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, PositionData item) {
    final active = item.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
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
                              color: active
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? const Color(0xFF16A34A)
                                    : AppColors.grey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _PositionFormDialog(position: item),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: () =>
                          _deleteItem(context, ref, item.id, item.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.grey100),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (item.departmentName != null &&
                    item.departmentName!.isNotEmpty)
                  _buildMetaRow(
                    Icons.corporate_fare_rounded,
                    'Department: ${item.departmentName!}',
                  ),
                if (item.level != null && item.level!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 14,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Level: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelBg(item.level),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getLevelColor(
                                item.level,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            item.level!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _getLevelColor(item.level),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
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
        ],
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
                // Delete Icon
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
                  l10n.deleteRoleTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [TextSpan(text: l10n.deleteRoleConfirm(name))],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey),
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
        await ref.read(hrRepositoryProvider).deletePosition(id);

        ref.invalidate(positionsProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Position deleted successfully"),
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
            l10n.failedToLoadPositions,
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
}

// ── Teams Tab ───────────────────────────────────────────────────────────────
class _TeamsTab extends ConsumerStatefulWidget {
  const _TeamsTab();

  @override
  ConsumerState<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<_TeamsTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  int? _filterDeptId;
  String _sortBy = 'name';
  bool _sortDesc = false;
  String? _filterActive;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamsAsync = ref.watch(teamsProvider);
    final deptsAsync = ref.watch(departmentsProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Search and Filters Bar
            Container(
              color: AppColors.textPrimary(context),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Search
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
                          hintText: l10n.searchTeamsHint,
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
                                    decoration: BoxDecoration(
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
                  // Sort Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'name' && !_sortDesc) {
                          _sortDesc = true;
                        } else if (_sortBy == 'name') {
                          _sortBy = 'headcount';
                          _sortDesc = false;
                        } else if (_sortBy == 'headcount' && !_sortDesc) {
                          _sortDesc = true;
                        } else {
                          _sortBy = 'name';
                          _sortDesc = false;
                        }
                      });
                    },
                    child: Container(
                      height: 46,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sortBy == 'headcount'
                                ? Icons.people_rounded
                                : Icons.sort_by_alpha_rounded,
                            size: 18,
                            color: AppColors.grey600,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _sortDesc
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Dept Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: deptsAsync.maybeWhen(
                        data: (depts) => DropdownButton<int?>(
                          value: _filterDeptId,
                          hint: Text(
                            l10n.allDepartmentsLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.grey500,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                l10n.allDeptsLabel,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            ...depts.map(
                              (d) => DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(
                                  d.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterDeptId = val),
                        ),
                        orElse: () => Text(l10n.loadingLabel),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Active Filter Dropdown
                  Container(
                    height: 46,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _filterActive,
                        hint: Text(
                          'All',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.grey500,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'true',
                            child: Text(
                              'Active',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'false',
                            child: Text(
                              'Inactive',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _filterActive = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Divider(height: 1, color: AppColors.grey200),
            // Content
            Expanded(
              child: teamsAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        item.name.toLowerCase().contains(_searchQuery) ||
                        (item.description ?? '').toLowerCase().contains(
                          _searchQuery,
                        );
                    final matchesDept =
                        _filterDeptId == null ||
                        item.departmentId == _filterDeptId;
                    final matchesActive =
                        _filterActive == null ||
                        (_filterActive == 'true' && (item.isActive ?? true)) ||
                        (_filterActive == 'false' && !(item.isActive ?? true));
                    return matchesSearch && matchesDept && matchesActive;
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

                  return filteredItems.isEmpty
                      ? _buildEmptyState(
                          context,
                          isFiltered:
                              _searchQuery.isNotEmpty || _filterDeptId != null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _buildItem(context, ref, filteredItems[i]),
                        );
                },
                loading: () => LoadingIndicator(message: l10n.loadingTeams),
                error: (e, _) => _errorWidget(ref, teamsProvider, l10n),
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
                  builder: (_) => const _TeamFormDialog(),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        l10n.addTeamBtn,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
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

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                size: 36,
                color: AppColors.warning,
              ),
            ),
            SizedBox(height: 16),
            Text(
              isFiltered ? 'No Matches Found' : 'No Teams Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Try adjusting your search query or filters.'
                  : 'Add a team to start building collaborative groups.',
              style: const TextStyle(fontSize: 13, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, TeamData item) {
    final active = item.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary(context),
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
                              color: active
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? const Color(0xFF16A34A)
                                    : AppColors.grey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.departmentName != null &&
                          item.departmentName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.departmentName!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _TeamFormDialog(team: item),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: () =>
                          _deleteItem(context, ref, item.id, item.name),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.grey100),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Team Leader Info
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.leaderName != null
                                  ? 'Leader: ${item.leaderName!}'
                                  : 'No Leader Assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.leaderName != null
                                    ? AppColors.grey700
                                    : AppColors.grey400,
                                fontWeight: item.leaderName != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontStyle: item.leaderName != null
                                    ? null
                                    : FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
                        '${item.employeesCount ?? 0} Members',
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
                // Delete Icon
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
                  l10n.deleteTeamTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [TextSpan(text: l10n.deleteTeamConfirm(name))],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey),
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
        await ref.read(hrRepositoryProvider).deleteTeam(id);

        ref.invalidate(teamsProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Team deleted successfully"),
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
            l10n.failedToLoadTeams,
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
}

// ── Org Chart Tab ───────────────────────────────────────────────────────────
class _OrgChartTab extends ConsumerStatefulWidget {
  const _OrgChartTab();

  @override
  ConsumerState<_OrgChartTab> createState() => _OrgChartTabState();
}

class _OrgChartTabState extends ConsumerState<_OrgChartTab> {
  late TextEditingController _searchCtrl;
  final TransformationController _transformCtrl = TransformationController();
  String _searchQuery = '';
  int _maxDepth = 2;
  String _layoutMode = 'hybrid';
  final Set<int> _collapsedNodes = {};

  // Dept colors for visual grouping
  static const _deptColors = [
    Color(0xFFEFF6FF), // orange
    Color(0xFFEFF6FF), // blue
    Color(0xFFF5F3FF), // purple
    Color(0xFFECFDF5), // emerald
    Color(0xFFFDF2F8), // pink
  ];
  static const _deptDots = [
    Color(0xFF0052FF),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];
  int _deptColorIdx = 0;
  final Map<String, int> _deptColorMap = {};

  Color _deptBg(String? deptName) {
    final key = deptName ?? '__none';
    if (!_deptColorMap.containsKey(key)) {
      _deptColorMap[key] = _deptColorIdx % _deptColors.length;
      _deptColorIdx++;
    }
    return _deptColors[_deptColorMap[key]!];
  }

  Color _deptDot(String? deptName) {
    final key = deptName ?? '__none';
    if (!_deptColorMap.containsKey(key)) {
      _deptColorMap[key] = _deptColorIdx % _deptDots.length;
      _deptColorIdx++;
    }
    return _deptDots[_deptColorMap[key]! % _deptDots.length];
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformCtrl.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.2, 3.0);
    final actualFactor = targetScale / currentScale;
    // ignore: deprecated_member_use
    matrix.scale(actualFactor);
    _transformCtrl.value = matrix;
  }

  bool _nodeMatches(OrgNode node, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return node.name.toLowerCase().contains(q) ||
        (node.positionName?.toLowerCase().contains(q) ?? false) ||
        (node.departmentName?.toLowerCase().contains(q) ?? false);
  }

  bool _anyChildMatches(OrgNode node, String query) {
    if (query.isEmpty) return false;
    if (!node.hasSubordinates) return false;
    return node.subordinates!.any(
      (child) => _nodeMatches(child, query) || _anyChildMatches(child, query),
    );
  }

  Widget _buildNode(OrgNode node, int depth) {
    final deptBgColor = _deptBg(node.departmentName);
    final deptDotColor = _deptDot(node.departmentName);
    final match = _nodeMatches(node, _searchQuery);
    final childMatch = _anyChildMatches(node, _searchQuery);
    final shouldShow = _searchQuery.isEmpty || match || childMatch;
    final isManuallyCollapsed = _collapsedNodes.contains(node.id);
    final isExpanded =
        !isManuallyCollapsed && (depth < _maxDepth || _maxDepth == -1);

    if (!shouldShow) return const SizedBox.shrink();

    final statusColors = {
      'active': const Color(0xFF16A34A),
      'on_leave': const Color(0xFFD97706),
      'probation': const Color(0xFF2563EB),
      'resigned': const Color(0xFFDC2626),
      'terminated': const Color(0xFFDC2626),
    };
    final statusColor =
        statusColors[node.employmentStatus] ?? AppColors.grey500;

    final nodeCard = Container(
      width: 280, // Fixed width for nodes to align nicely
      decoration: BoxDecoration(
        color: deptBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: deptBgColor.withAlpha(180), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dept band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(150),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: deptDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.departmentName ?? '—',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF374151), Color(0xFF111827)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        image: node.photo != null && node.photo!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  node.photo!.startsWith('http')
                                      ? node.photo!
                                      : '${DioClient.storageUrl}/${node.photo!.startsWith('/') ? node.photo!.substring(1) : node.photo!}',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: node.photo == null || node.photo!.isEmpty
                          ? Center(
                              child: Text(
                                node.initials,
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: deptDotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.positionName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          node.positionName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          node.employmentStatus
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Children count
                if (node.hasSubordinates)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      '${node.subordinatesCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                if (node.email != null && node.email!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('mailto:${node.email}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                if (node.phone != null && node.phone!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('tel:${node.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/employee/${node.id}');
                  },
                  child: Row(
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 10,
                        color: AppColors.grey400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Expand/Collapse button
          if (node.hasSubordinates)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_collapsedNodes.contains(node.id)) {
                      _collapsedNodes.remove(node.id);
                    } else {
                      _collapsedNodes.add(node.id);
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${node.subordinatesCount} ${node.subordinatesCount != 1 ? "reports" : "report"}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
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

    if (!node.hasSubordinates || !isExpanded) {
      if (depth == 0) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: nodeCard,
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: nodeCard,
      );
    }

    if (depth == 0 && _layoutMode == 'hybrid') {
      // Horizontal layout for root's children
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          nodeCard,
          Container(width: 2, height: 32, color: AppColors.grey300),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: node.subordinates!.map((child) {
              final isFirst = child == node.subordinates!.first;
              final isLast = child == node.subordinates!.last;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal connector
                  Row(
                    children: [
                      Container(
                        width: 156, // Half of 280 + 16 margin
                        height: 2,
                        color: isFirst ? Colors.transparent : AppColors.grey300,
                      ),
                      Container(
                        width: 156,
                        height: 2,
                        color: isLast ? Colors.transparent : AppColors.grey300,
                      ),
                    ],
                  ),
                  Container(width: 2, height: 16, color: AppColors.grey300),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildNode(child, depth + 1),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      );
    }

    // Vertical layout for teams
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nodeCard,
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.subordinates!.map((child) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 24,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.grey300, width: 2),
                          bottom: BorderSide(
                            color: AppColors.grey300,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildNode(child, depth + 1),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  int _countNodes(List<OrgNode> nodes) {
    int c = nodes.length;
    for (final n in nodes) {
      if (n.hasSubordinates) c += _countNodes(n.subordinates!);
    }
    return c;
  }

  int _maxTreeDepth(List<OrgNode> nodes, int d) {
    if (nodes.isEmpty) return d;
    int maxD = d + 1;
    for (final n in nodes) {
      if (n.hasSubordinates) {
        final cd = _maxTreeDepth(n.subordinates!, d + 1);
        if (cd > maxD) maxD = cd;
      }
    }
    return maxD;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orgChartAsync = ref.watch(orgChartProvider);

    return orgChartAsync.when(
      data: (tree) {
        if (tree.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_tree_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.noOrgChartTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.noOrgChartDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final totalCount = _countNodes(tree);
        final maxDepthVal = _maxTreeDepth(tree, 0);

        return Column(
          children: [
            // Search + Depth
            Container(
              color: AppColors.textPrimary(context),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search
                  Container(
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
                        hintText: l10n.searchOrgChartHint,
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
                                  decoration: BoxDecoration(
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
                  const SizedBox(height: 10),
                  // Depth control + stats
                  Row(
                    children: [
                      // Stats
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Text(
                          l10n.orgChartStats(totalCount, maxDepthVal),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                      Spacer(),
                      // Layout Toggle
                      Container(
                        height: 34,
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _layoutMode = 'hybrid'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _layoutMode == 'hybrid'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _layoutMode == 'hybrid'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(10),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.account_tree_rounded,
                                  size: 16,
                                  color: _layoutMode == 'hybrid'
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _layoutMode = 'vertical'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _layoutMode == 'vertical'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _layoutMode == 'vertical'
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(10),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.format_list_bulleted_rounded,
                                  size: 16,
                                  color: _layoutMode == 'vertical'
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Depth Dropdown
                      Container(
                        height: 34,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _maxDepth,
                            icon: const Icon(
                              Icons.unfold_more_rounded,
                              size: 16,
                              color: AppColors.grey500,
                            ),
                            iconSize: 16,
                            elevation: 4,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() => _maxDepth = newValue);
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: -1,
                                child: Text(l10n.expandAll),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(l10n.showLevel1),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(l10n.showLevel2),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text(l10n.showLevel3),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text(l10n.showLevel4),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text(l10n.showLevel5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.grey200),
            // Tree
            Expanded(
              child: Container(
                color: const Color(
                  0xFFF1F5F9,
                ), // Slight gray background for contrast
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformCtrl,
                      minScale: 0.2,
                      maxScale: 3.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(
                        500,
                      ), // Lots of pan room
                      child: Padding(
                        padding: const EdgeInsets.all(64.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: tree
                              .map((root) => _buildNode(root, 0))
                              .toList(),
                        ),
                      ),
                    ),
                    // Legend
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Levels',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.grey400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...[
                              'C-Level',
                              'Director',
                              'Manager',
                              'Lead',
                              'Staff',
                            ].asMap().entries.map((entry) {
                              final i = entry.key;
                              final label = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _deptDots[i % _deptDots.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoomIn',
                            onPressed: () => _zoom(1.3),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(Icons.add_rounded),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoomOut',
                            onPressed: () => _zoom(1 / 1.3),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(Icons.remove_rounded),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoomReset',
                            onPressed: () =>
                                _transformCtrl.value = Matrix4.identity(),
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.grey700,
                            child: const Icon(
                              Icons.center_focus_strong_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => LoadingIndicator(message: l10n.loadingOrgChart),
      error: (e, _) => Center(
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
              l10n.failedToLoadOrgChart,
              style: const TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(orgChartProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentFormDialog extends ConsumerStatefulWidget {
  final DepartmentData? department;
  const _DepartmentFormDialog({this.department});

  @override
  ConsumerState<_DepartmentFormDialog> createState() =>
      _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends ConsumerState<_DepartmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  int? _branchId;
  int? _parentId;
  int? _managerId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.department;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _branchId = d?.branchId;
    _parentId = d?.parentId;
    _managerId = d?.managerId;
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.department == null) {
        await ref
            .read(hrRepositoryProvider)
            .createDepartment(
              name: _nameCtrl.text,
              branchId: _branchId,
              parentId: _parentId,
              managerId: _managerId,
              isActive: _isActive,
            );
      } else {
        await ref
            .read(hrRepositoryProvider)
            .updateDepartment(
              widget.department!.id,
              name: _nameCtrl.text,
              branchId: _branchId,
              parentId: _parentId,
              managerId: _managerId,
              isActive: _isActive,
            );
      }
      ref.invalidate(departmentsProvider);
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
    final branchesAsync = ref.watch(branchesProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.infoLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.corporate_fare_rounded,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.department == null
                            ? 'Create Department'
                            : 'Edit Department',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Text(
                        'Set organizational unit boundaries',
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
                          labelText: 'Department Name',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Branch Dropdown
                      branchesAsync.when(
                        data: (branches) => DropdownButtonFormField<int>(
                          initialValue: _branchId,
                          decoration: const InputDecoration(
                            labelText: 'Office Branch',
                            prefixIcon: Icon(
                              Icons.place_outlined,
                              color: AppColors.grey400,
                              size: 20,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Branch'),
                            ),
                            ...branches.map(
                              (b) => DropdownMenuItem<int>(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() => _branchId = val),
                        ),
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading branches: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Parent Department Dropdown
                      deptsAsync.when(
                        data: (depts) {
                          // Exclude current department from parents to avoid loops
                          final availableDepts = widget.department == null
                              ? depts
                              : depts
                                    .where((d) => d.id != widget.department!.id)
                                    .toList();

                          return DropdownButtonFormField<int>(
                            initialValue: _parentId,
                            decoration: const InputDecoration(
                              labelText: 'Parent Department',
                              prefixIcon: Icon(
                                Icons.account_tree_outlined,
                                color: AppColors.grey400,
                                size: 20,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No Parent (Root)'),
                              ),
                              ...availableDepts.map(
                                (d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.name),
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => _parentId = val),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading departments: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Manager Dropdown
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
                              labelText: 'Department Manager',
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
                          'Error: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 14),

                      SwitchListTile(
                        title: const Text(
                          'Active Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Department is operational',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isActive,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isActive = val),
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
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? SizedBox(
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

class _PositionFormDialog extends ConsumerStatefulWidget {
  final PositionData? position;
  const _PositionFormDialog({this.position});

  @override
  ConsumerState<_PositionFormDialog> createState() =>
      _PositionFormDialogState();
}

class _PositionFormDialogState extends ConsumerState<_PositionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  int? _departmentId;
  String? _level;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _levels = [
    'Junior',
    'Mid-Level',
    'Senior',
    'Lead',
    'Manager',
    'Director',
    'VP',
    'C-Level',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.position;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _departmentId = p?.departmentId;
    _level = p?.level;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.position == null) {
        await ref
            .read(hrRepositoryProvider)
            .createPosition(
              name: _nameCtrl.text,
              departmentId: _departmentId,
              level: _level,
              isActive: _isActive,
            );
      } else {
        await ref
            .read(hrRepositoryProvider)
            .updatePosition(
              widget.position!.id,
              name: _nameCtrl.text,
              departmentId: _departmentId,
              level: _level,
              isActive: _isActive,
            );
      }
      ref.invalidate(positionsProvider);
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
    final deptsAsync = ref.watch(departmentsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.position == null
                            ? 'Create Position'
                            : 'Edit Position',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Text(
                        'Set job title responsibilities and level',
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
                          labelText: 'Role Title',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Department Dropdown
                      deptsAsync.when(
                        data: (depts) => DropdownButtonFormField<int>(
                          initialValue: _departmentId,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(
                              Icons.corporate_fare_rounded,
                              color: AppColors.grey400,
                              size: 20,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Department (General)'),
                            ),
                            ...depts.map(
                              (d) => DropdownMenuItem<int>(
                                value: d.id,
                                child: Text(d.name),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _departmentId = val),
                        ),
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading depts: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Level Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _level,
                        decoration: const InputDecoration(
                          labelText: 'Job Seniority Level',
                          prefixIcon: Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('No Level specified'),
                          ),
                          ..._levels.map(
                            (lvl) => DropdownMenuItem<String>(
                              value: lvl,
                              child: Text(lvl),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _level = val),
                      ),
                      const SizedBox(height: 14),

                      SwitchListTile(
                        title: const Text(
                          'Active Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Allow assigning employees to this role',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isActive,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isActive = val),
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
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? SizedBox(
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

class _TeamFormDialog extends ConsumerStatefulWidget {
  final TeamData? team;
  const _TeamFormDialog({this.team});

  @override
  ConsumerState<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends ConsumerState<_TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  int? _departmentId;
  int? _leaderId;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _departmentId = t?.departmentId;
    _leaderId = t?.leaderId;
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.team == null) {
        await ref
            .read(hrRepositoryProvider)
            .createTeam(
              name: _nameCtrl.text,
              description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
              departmentId: _departmentId,
              leaderId: _leaderId,
              isActive: _isActive,
            );
      } else {
        await ref
            .read(hrRepositoryProvider)
            .updateTeam(
              widget.team!.id,
              name: _nameCtrl.text,
              description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
              departmentId: _departmentId,
              leaderId: _leaderId,
              isActive: _isActive,
            );
      }
      ref.invalidate(teamsProvider);
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
    final deptsAsync = ref.watch(departmentsProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.team == null ? 'Create Team' : 'Edit Team',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const Text(
                        'Set collaborative squads and assign leader',
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
                          labelText: 'Team Name',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Department Dropdown
                      deptsAsync.when(
                        data: (depts) => DropdownButtonFormField<int>(
                          initialValue: _departmentId,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(
                              Icons.corporate_fare_rounded,
                              color: AppColors.grey400,
                              size: 20,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Department (General)'),
                            ),
                            ...depts.map(
                              (d) => DropdownMenuItem<int>(
                                value: d.id,
                                child: Text(d.name),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _departmentId = val),
                        ),
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading depts: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Leader Dropdown
                      employeesAsync.when(
                        data: (employees) {
                          final hasLeader =
                              _leaderId != null &&
                              employees.any((e) => e.userId == _leaderId);
                          final initialLeaderId = hasLeader ? _leaderId : null;
                          return DropdownButtonFormField<int>(
                            initialValue: initialLeaderId,
                            decoration: const InputDecoration(
                              labelText: 'Team Leader',
                              prefixIcon: Icon(
                                Icons.shield_outlined,
                                color: AppColors.grey400,
                                size: 20,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No Leader Assigned'),
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
                            onChanged: (val) => setState(() => _leaderId = val),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Text(
                          'Error loading employees: $err',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 14),

                      SwitchListTile(
                        title: const Text(
                          'Active Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Allow assigning employees to this team',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isActive,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isActive = val),
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
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: _isLoading
                        ? SizedBox(
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
