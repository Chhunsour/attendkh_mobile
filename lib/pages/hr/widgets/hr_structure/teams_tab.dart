import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

// ── Teams Tab ───────────────────────────────────────────────────────────────
class TeamsTab extends ConsumerStatefulWidget {
  const TeamsTab({super.key});

  @override
  ConsumerState<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<TeamsTab> {
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  int? _filterDeptId;
  String _sortBy = 'name';
  bool _sortDesc = false;
  String? _filterActive;
  bool _showFilters = false;

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

  int get _activeFilterCount {
    int count = 0;
    if (_filterDeptId != null) count++;
    if (_filterActive != null) count++;
    if (_sortBy != 'name' || _sortDesc) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _filterDeptId = null;
      _filterActive = null;
      _sortBy = 'name';
      _sortDesc = false;
    });
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
              color: AppColors.surface(context),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
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

                          // Dept Filter Dropdown
                          const Text('Department', style: TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: deptsAsync.maybeWhen(
                                data: (depts) => DropdownButton<int?>(
                                  value: _filterDeptId,
                                  isExpanded: true,
                                  hint: Text(
                                    l10n.allDepartmentsLabel,
                                    style: const TextStyle(fontSize: 12, color: AppColors.grey600),
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(l10n.allDeptsLabel, style: const TextStyle(fontSize: 12)),
                                    ),
                                    ...depts.map((d) => DropdownMenuItem<int?>(
                                      value: d.id,
                                      child: Text(d.name, style: const TextStyle(fontSize: 12)),
                                    )),
                                  ],
                                  onChanged: (val) => setState(() => _filterDeptId = val),
                                ),
                                orElse: () => Text(l10n.loadingLabel),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

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
            // Divider
            const Divider(height: 1, color: AppColors.grey200),
            // Content
            Expanded(
              child: teamsAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    if (_searchQuery.isNotEmpty) {
                      final name = item.name.toLowerCase();
                      final desc = (item.description ?? '').toLowerCase();
                      if (!name.contains(_searchQuery) &&
                          !desc.contains(_searchQuery)) {
                        return false;
                      }
                    }
                    if (_filterDeptId != null &&
                        item.departmentId != _filterDeptId) {
                      return false;
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
                      ref.invalidate(teamsProvider);
                      return await ref.read(teamsProvider.future);
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
                                        Icons.groups_rounded,
                                        size: 48,
                                        color: AppColors.grey300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty || _activeFilterCount > 0
                                            ? 'No teams match your filters'
                                            : l10n.noTeamsFound,
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
                  builder: (_) => const TeamFormDialog(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.addTeamBtn,
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

  Widget _buildItem(BuildContext context, WidgetRef ref, TeamData item) {
    final active = item.isActive ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  decoration: const BoxDecoration(
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
                        builder: (_) => TeamFormDialog(team: item),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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

// ── Team Form Dialog ────────────────────────────────────────────────────────
class TeamFormDialog extends ConsumerStatefulWidget {
  final TeamData? team;
  const TeamFormDialog({super.key, this.team});

  @override
  ConsumerState<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends ConsumerState<TeamFormDialog> {
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
                  decoration: const BoxDecoration(
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

                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
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
