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
                title: 'Total Roles',
                value: '${payload.roles.length}',
                icon: Icons.shield_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'System Core',
                value: '$systemCount',
                icon: Icons.lock_outline_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Custom',
                value: '$customCount',
                icon: Icons.tune_rounded,
                color: const Color(0xFF10B981),
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 48, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  _searchTerm.isNotEmpty ? 'No roles matching "$_searchTerm"' : l10n.noSystemRolesFound,
                  style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
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
                    Text(
                      isSuperAdmin
                          ? 'Unrestricted Full Platform Access'
                          : '${perms.length} assigned permissions',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).padding.bottom + MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? l10n.editRoleTitle : l10n.createNewRoleTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.grey500),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        '${selectedPermissions.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.38,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: payload.allPermissions.map((perm) {
                          final isSelected = selectedPermissions.contains(perm);
                          return FilterChip(
                            label: Text(_formatPerm(perm)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedPermissions.add(perm);
                                } else {
                                  selectedPermissions.remove(perm);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                            checkmarkColor: const Color(0xFF7C3AED),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF8B5CF6) : AppColors.grey200,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF7C3AED) : AppColors.grey700,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
