import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/hr_repository.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rolesAsync = ref.watch(rolesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.rolesPermissionsTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          rolesAsync.when(
            data: (items) => items.isEmpty
                ? Center(child: Text(l10n.noCustomRoles, style: const TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
                        child: Row(
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shield, color: AppColors.info, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              if (r.permissionsCount != null) Text(l10n.permissionsCount(r.permissionsCount!), style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                            ])),
                            const Icon(Icons.chevron_right, color: AppColors.grey400),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => LoadingIndicator(message: l10n.loadingRoles),
            error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(rolesProvider), icon: const Icon(Icons.refresh), label: Text(l10n.retry))),
          ),
          Positioned(
            right: 16, bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateRoleDialog(context, ref),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createRoleTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.roleNameLabel, hintText: l10n.roleNameHint)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await HrRepository().createRole(name: nameCtrl.text.trim());
              ref.invalidate(rolesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.roleCreatedSuccess), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: Text(l10n.createBtn)),
        ],
      ),
    );
  }
}
