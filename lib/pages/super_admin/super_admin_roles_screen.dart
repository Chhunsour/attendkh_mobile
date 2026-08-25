// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/super_admin_role_repository.dart';
import 'package:mpg_hr_mobile_app/providers/super_admin_role_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

const _systemRoles = [
  'super_admin',
  'company_owner',
  'branch_manager',
  'employee',
];

class _PermissionCategory {
  final String id;
  final String label;
  final IconData icon;
  final List<String> match;

  const _PermissionCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.match,
  });
}

const _permissionCategories = [
  _PermissionCategory(
    id: 'organization',
    label: 'Employees & Organization',
    icon: Icons.people_alt_rounded,
    match: ['manage-employees', 'manage-departments', 'manage-branches', 'manage-positions'],
  ),
  _PermissionCategory(
    id: 'attendance',
    label: 'Attendance & Shifts',
    icon: Icons.access_time_rounded,
    match: ['manage-attendance', 'manage-branch-attendance', 'manage-branch-shifts'],
  ),
  _PermissionCategory(
    id: 'leaves',
    label: 'Leave & Holidays',
    icon: Icons.beach_access_rounded,
    match: ['manage-leave', 'approve-branch-leaves', 'manage-holidays'],
  ),
  _PermissionCategory(
    id: 'finance',
    label: 'Payroll & Expenses',
    icon: Icons.payments_rounded,
    match: ['manage-payroll', 'manage-expenses', 'approve-expenses'],
  ),
  _PermissionCategory(
    id: 'talent',
    label: 'Recruitment & Performance',
    icon: Icons.work_outline_rounded,
    match: ['manage-recruitment', 'manage-performance'],
  ),
  _PermissionCategory(
    id: 'assets_docs',
    label: 'Assets & Documents',
    icon: Icons.folder_open_rounded,
    match: ['manage-assets', 'manage-documents'],
  ),
  _PermissionCategory(
    id: 'company',
    label: 'Company & Communication',
    icon: Icons.campaign_rounded,
    match: ['view-dashboard', 'view-company', 'manage-announcements'],
  ),
  _PermissionCategory(
    id: 'administration',
    label: 'System & Administration',
    icon: Icons.admin_panel_settings_rounded,
    match: ['manage-settings', 'manage-roles'],
  ),
];

String _formatName(String name) => name
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

String _formatPerm(String name) => name
    .replaceAll('-', ' ')
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class SuperAdminRolesScreen extends ConsumerStatefulWidget {
  const SuperAdminRolesScreen({super.key});

  @override
  ConsumerState<SuperAdminRolesScreen> createState() => _SuperAdminRolesScreenState();
}

class _SuperAdminRolesScreenState extends ConsumerState<SuperAdminRolesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _typeFilter = 'all'; // 'all', 'system', 'custom'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(superAdminRolesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.platformRolesTitle,
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
            onPressed: () => ref.invalidate(superAdminRolesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final payload = ref.read(superAdminRolesProvider).value;
          if (payload != null) {
            _showRoleModal(payload, l10n);
          }
        },
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_moderator_rounded, size: 20),
        label: const Text(
          'New Role',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(superAdminRolesProvider),
        child: rolesAsync.when(
          loading: () => LoadingIndicator(message: l10n.loadingRoles),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load roles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(superAdminRolesProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (payload) => _buildContent(payload, l10n),
        ),
      ),
    );
  }

  Widget _buildContent(SuperAdminRolesPayload payload, AppLocalizations l10n) {
    final systemCount = payload.roles.where((r) => _systemRoles.contains(r.name)).length;
    final customCount = payload.roles.where((r) => !_systemRoles.contains(r.name)).length;
    final totalAssignedUsers = payload.roles.fold<int>(0, (sum, r) => sum + (r.usersCount ?? 0));

    final filtered = payload.roles.where((r) {
      final isSys = _systemRoles.contains(r.name);
      if (_typeFilter == 'system' && !isSys) return false;
      if (_typeFilter == 'custom' && isSys) return false;

      if (_searchTerm.isNotEmpty) {
        final matchName = r.name.toLowerCase().contains(_searchTerm);
        final matchPerms = r.permissions?.any((p) => p.toLowerCase().contains(_searchTerm)) ?? false;
        return matchName || matchPerms;
      }
      return true;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // ── Stat Overview Cards ──
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total',
                value: '${payload.roles.length}',
                icon: Icons.shield_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'System',
                value: '$systemCount',
                icon: Icons.lock_outline_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Custom',
                value: '$customCount',
                icon: Icons.tune_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Users',
                value: '$totalAssignedUsers',
                icon: Icons.people_outline_rounded,
                color: const Color(0xFF3B82F6),
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
            onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
            style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Search roles or permissions...',
              hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.grey400, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Filter Chips ──
        Row(
          children: [
            _buildFilterChip('All (${payload.roles.length})', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('System ($systemCount)', 'system'),
            const SizedBox(width: 8),
            _buildFilterChip('Custom ($customCount)', 'custom'),
          ],
        ),

        const SizedBox(height: 16),

        // ── Role Cards ──
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield_outlined, size: 40, color: AppColors.grey400),
                const SizedBox(height: 10),
                Text(
                  'No roles match your search',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try typing another keyword or change your filter',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          )
        else
          ...filtered.map((r) => _buildRoleCard(r, payload, l10n)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
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
                  fontSize: 10.5,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return InkWell(
      onTap: () => setState(() => _typeFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : AppColors.grey200),
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

  Widget _buildRoleCard(
    RoleData r,
    SuperAdminRolesPayload payload,
    AppLocalizations l10n,
  ) {
    final isSystem = _systemRoles.contains(r.name);
    final isSuperAdmin = r.name == 'super_admin';
    final perms = r.permissions ?? [];
    final usersCount = r.usersCount ?? 0;

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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSystem
                      ? (isSuperAdmin ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : const Color(0xFFF59E0B).withValues(alpha: 0.12))
                      : const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSuperAdmin ? Icons.military_tech_rounded : (isSystem ? Icons.lock_outline_rounded : Icons.shield_outlined),
                  color: isSystem
                      ? (isSuperAdmin ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B))
                      : const Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatName(r.name),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSystem ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSystem ? 'SYSTEM' : 'CUSTOM',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isSystem ? const Color(0xFFD97706) : const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          isSuperAdmin
                              ? 'Full Platform Access'
                              : '${perms.length} permissions',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                        const SizedBox(width: 6),
                        const Icon(Icons.people_alt_outlined, size: 12, color: AppColors.grey500),
                        const SizedBox(width: 3),
                        Text(
                          '$usersCount ${usersCount == 1 ? "user" : "users"}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF8B5CF6), size: 18),
                tooltip: 'Edit Permissions',
                onPressed: () => _showRoleModal(payload, l10n, role: r),
              ),
              if (!isSystem)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  tooltip: 'Delete Role',
                  onPressed: () => _confirmDelete(r.id, r.name, l10n),
                ),
            ],
          ),
          if (isSuperAdmin) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                  SizedBox(width: 5),
                  Text(
                    'All System Modules & Operations Granted',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
          ] else if (perms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...perms.take(4).map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _formatPerm(p),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
                if (perms.length > 4)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      '+${perms.length - 4} more',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRoleModal(
    SuperAdminRolesPayload payload,
    AppLocalizations l10n, {
    RoleData? role,
  }) {
    final isEditing = role != null;
    final isSystemRole = isEditing && _systemRoles.contains(role.name);

    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final Set<String> selectedPermissions = Set.from(role?.permissions ?? []);

    // Build category list with unmatched items
    final List<Map<String, dynamic>> categories = [];
    final assignedPerms = <String>{};

    for (final cat in _permissionCategories) {
      final items = payload.allPermissions.where((p) => cat.match.contains(p)).toList();
      if (items.isNotEmpty) {
        assignedPerms.addAll(items);
        categories.add({
          'id': cat.id,
          'label': cat.label,
          'icon': cat.icon,
          'items': items,
        });
      }
    }

    final otherItems = payload.allPermissions.where((p) => !assignedPerms.contains(p)).toList();
    if (otherItems.isNotEmpty) {
      categories.add({
        'id': 'other',
        'label': 'Other Permissions',
        'icon': Icons.shield_outlined,
        'items': otherItems,
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).padding.bottom + MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? l10n.editRoleTitle : l10n.createNewRoleTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            if (isEditing)
                              Text(
                                '${role.usersCount ?? 0} active users assigned',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.grey500),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Role Name Input
                    TextFormField(
                      controller: nameCtrl,
                      enabled: !isSystemRole,
                      decoration: InputDecoration(
                        labelText: l10n.roleNameLabel,
                        hintText: l10n.roleNameHint,
                        filled: true,
                        fillColor: isSystemRole ? AppColors.grey100 : AppColors.grey50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                    if (isSystemRole)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.coreSystemRolesWarning,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Permissions Sub-header & Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.permissionsLabel,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              '${selectedPermissions.length} / ${payload.allPermissions.length} selected',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.addAll(payload.allPermissions);
                                });
                              },
                              icon: const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF8B5CF6)),
                              label: const Text(
                                'Select All',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.clear();
                                });
                              },
                              icon: const Icon(Icons.clear_all_rounded, size: 15, color: AppColors.grey500),
                              label: const Text(
                                'Clear All',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey600),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Scrollable Grouped Modules List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final cat = categories[idx];
                            final catLabel = cat['label'] as String;
                            final catIcon = cat['icon'] as IconData;
                            final catItems = (cat['items'] as List<dynamic>).cast<String>();

                            final selectedInCat = catItems.where((p) => selectedPermissions.contains(p)).length;
                            final isAllSelectedInCat = selectedInCat == catItems.length && catItems.isNotEmpty;

                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(catIcon, size: 15, color: const Color(0xFF8B5CF6)),
                                          const SizedBox(width: 6),
                                          Text(
                                            catLabel,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: selectedInCat > 0 ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : AppColors.grey100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '$selectedInCat/${catItems.length}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: selectedInCat > 0 ? const Color(0xFF7C3AED) : AppColors.grey500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setModalState(() {
                                            if (isAllSelectedInCat) {
                                              selectedPermissions.removeAll(catItems);
                                            } else {
                                              selectedPermissions.addAll(catItems);
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            isAllSelectedInCat ? 'Deselect' : 'Select All',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Chips
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: catItems.map((perm) {
                                      final isSelected = selectedPermissions.contains(perm);
                                      return FilterChip(
                                        label: Text(_formatPerm(perm)),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setModalState(() {
                                            if (selected) {
                                              selectedPermissions.add(perm);
                                            } else {
                                              selectedPermissions.remove(perm);
                                            }
                                          });
                                        },
                                        selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                                        checkmarkColor: const Color(0xFF7C3AED),
                                        backgroundColor: AppColors.grey50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: isSelected ? const Color(0xFF8B5CF6) : AppColors.grey200,
                                          ),
                                        ),
                                        labelStyle: TextStyle(
                                          color: isSelected ? const Color(0xFF7C3AED) : AppColors.grey700,
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                try {
                                  final repo = SuperAdminRoleRepository();
                                  if (isEditing) {
                                    await repo.updateRole(
                                      role.id,
                                      nameCtrl.text.trim(),
                                      selectedPermissions.toList(),
                                    );
                                  } else {
                                    await repo.createRole(
                                      nameCtrl.text.trim(),
                                      selectedPermissions.toList(),
                                    );
                                  }
                                  ref.invalidate(superAdminRolesProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing ? l10n.roleUpdatedSuccess : l10n.roleCreatedSuccess,
                                        ),
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
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                isEditing ? l10n.saveChanges : l10n.btnCreateRole,
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
      },
    );
  }

  void _confirmDelete(int roleId, String roleName, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteRoleTitle),
        content: Text(l10n.deleteRoleConfirm(roleName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await SuperAdminRoleRepository().deleteRole(roleId);
                ref.invalidate(superAdminRolesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.roleDeletedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.failedToDeleteRole}: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.btnDelete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
