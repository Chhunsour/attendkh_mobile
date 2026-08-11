import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/services/super_admin_role_repository.dart';
import 'package:mpg_hr_mobile_app/providers/super_admin_role_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class SuperAdminRolesScreen extends ConsumerWidget {
  const SuperAdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(superAdminRolesProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.platformRolesTitle,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          rolesAsync.when(
            data: (payload) {
              final items = payload.roles;
              if (items.isEmpty) {
                return Center(child: Text(l10n.noSystemRolesFound, style: const TextStyle(color: AppColors.grey400)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final r = items[i];
                  final isSystem = ['super_admin', 'company_owner', 'company_admin', 'branch_manager', 'employee'].contains(r.name);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight, 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: AppColors.grey200)
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44, 
                          decoration: BoxDecoration(
                            color: isSystem ? AppColors.warningLight : AppColors.infoLight, 
                            borderRadius: BorderRadius.circular(10)
                          ), 
                          child: Icon(
                            isSystem ? Icons.lock : Icons.shield, 
                            color: isSystem ? AppColors.warning : AppColors.info, 
                            size: 22
                          )
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          if (r.permissionsCount != null) Text(l10n.permissionsCount(r.permissionsCount!), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                          onPressed: () => _showRoleModal(context, ref, payload, l10n, role: r),
                        ),
                        if (!isSystem)
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                            onPressed: () => _confirmDelete(context, ref, r.id, r.name, l10n),
                          )
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => LoadingIndicator(message: l10n.loadingRoles),
            error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(superAdminRolesProvider), icon: const Icon(Icons.refresh), label: Text(l10n.retry))),
          ),
          Positioned(
            right: 16, bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                final payload = ref.read(superAdminRolesProvider).value;
                if (payload != null) {
                  _showRoleModal(context, ref, payload, l10n);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleModal(BuildContext context, WidgetRef ref, SuperAdminRolesPayload payload, AppLocalizations l10n, {RoleData? role}) {
    final isEditing = role != null;
    final isSystemRole = isEditing && ['super_admin', 'company_owner', 'company_admin', 'branch_manager', 'employee'].contains(role.name);
    
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final Set<String> selectedPermissions = Set.from(role?.permissions ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24, left: 24, right: 24,
                bottom: MediaQuery.of(ctx).padding.bottom + MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    enabled: !isSystemRole,
                    decoration: InputDecoration(
                      labelText: l10n.roleNameLabel,
                      hintText: l10n.roleNameHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (isSystemRole)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(l10n.coreSystemRolesWarning, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ),
                  const SizedBox(height: 20),
                  Text(l10n.permissionsLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey800)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: payload.allPermissions.map((perm) {
                          final isSelected = selectedPermissions.contains(perm);
                          return FilterChip(
                            label: Text(perm.replaceAll('_', ' ')),
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
                            selectedColor: AppColors.primary.withAlpha(50),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.grey700,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        try {
                          final repo = SuperAdminRoleRepository();
                          if (isEditing) {
                            await repo.updateRole(role.id, nameCtrl.text.trim(), selectedPermissions.toList());
                          } else {
                            await repo.createRole(nameCtrl.text.trim(), selectedPermissions.toList());
                          }
                          ref.invalidate(superAdminRolesProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEditing ? '✅ ${l10n.roleUpdatedSuccess}' : '✅ ${l10n.roleCreatedSuccess}'), backgroundColor: AppColors.success)
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger)
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isEditing ? l10n.saveChanges : l10n.btnCreateRole, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int roleId, String roleName, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRoleTitle),
        content: Text(l10n.deleteRoleConfirm(roleName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              try {
                await SuperAdminRoleRepository().deleteRole(roleId);
                ref.invalidate(superAdminRolesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${l10n.roleDeletedSuccess}'), backgroundColor: AppColors.success));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${l10n.failedToDeleteRole}: $e'), backgroundColor: AppColors.danger));
              }
            }, 
            child: Text(l10n.btnDelete, style: const TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}
