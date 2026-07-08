import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminAssetsScreen extends ConsumerWidget {
  const AdminAssetsScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Assets Directory',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          assetsAsync.when(
            data: (items) => items.isEmpty
                ? const Center(child: Text('No assets', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = items[i];
                      final statusColor = a.status == 'assigned' ? AppColors.info : a.status == 'available' ? AppColors.success : AppColors.grey400;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.inventory_2, color: statusColor, size: 22)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  if (a.type != null) Text(a.type!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                                  if (a.serialNumber != null) Text('SN: ${a.serialNumber}', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(a.status.substring(0, 1).toUpperCase() + a.status.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                                  if (a.assignedTo != null) ...[
                                    const SizedBox(height: 4),
                                    Text(a.assignedTo!, style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                  ],
                                ]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              if (a.status == 'available')
                                Expanded(child: OutlinedButton.icon(onPressed: () => _assignAsset(context, ref, a.id), icon: const Icon(Icons.person_add, size: 16), label: const Text('Assign'))),
                              if (a.status == 'assigned')
                                Expanded(child: OutlinedButton.icon(onPressed: () => _returnAsset(context, ref, a.id), icon: const Icon(Icons.keyboard_return, size: 16), label: const Text('Return'))),
                              IconButton(icon: const Icon(Icons.history, size: 18, color: AppColors.info), onPressed: () => _showHistory(context, a.id, a.name)),
                              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: () => _deleteAsset(context, ref, a.id, a.name)),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const LoadingIndicator(message: 'Loading assets...'),
            error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(assetsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
          ),
          Positioned(
            right: 16, bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateDialog(context, ref),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Asset'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name', hintText: 'e.g. MacBook Pro 16"')),
          const SizedBox(height: 12),
          TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type', hintText: 'e.g. Laptop')),
          const SizedBox(height: 12),
          TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number', hintText: 'Optional')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createAsset(name: nameCtrl.text.trim(), type: typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : null, serialNumber: serialCtrl.text.trim().isNotEmpty ? serialCtrl.text.trim() : null);
              ref.invalidate(assetsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Asset created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  void _assignAsset(BuildContext context, WidgetRef ref, int assetId) {
    final empIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Asset'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (empIdCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().assignAsset(assetId, int.parse(empIdCtrl.text.trim()));
              ref.invalidate(assetsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Asset assigned'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Assign')),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, int assetId, String assetName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssetHistorySheet(assetId: assetId, assetName: assetName),
    );
  }

  Future<void> _deleteAsset(BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text('Delete Asset'), content: Text('Delete "$name"?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
      ]),
    );
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteAsset(id);
        ref.invalidate(assetsProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Asset deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _returnAsset(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(title: const Text('Return Asset'), content: const Text('Mark this asset as returned?'), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Return')),
      ]),
    );
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().returnAsset(id);
        ref.invalidate(assetsProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Asset returned'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _AssetHistorySheet extends StatefulWidget {
  final int assetId;
  final String assetName;
  const _AssetHistorySheet({required this.assetId, required this.assetName});

  @override
  State<_AssetHistorySheet> createState() => _AssetHistorySheetState();
}

class _AssetHistorySheetState extends State<_AssetHistorySheet> {
  bool _isLoading = true;
  List<AssetAssignmentData> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await AdminOperationsRepository().getAssetHistory(widget.assetId);
      setState(() { _history = history; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Assignment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                  Text(widget.assetName, style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                ]),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading history...')
                : _history.isEmpty
                    ? const Center(child: Text('No assignment history', style: TextStyle(color: AppColors.grey400)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final h = _history[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey200)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.person, size: 16, color: AppColors.grey500),
                                const SizedBox(width: 6),
                                Text(h.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ]),
                              const SizedBox(height: 4),
                              Text('Assigned: ${h.assignedDate}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                              if (h.returnedDate != null) Text('Returned: ${h.returnedDate}', style: TextStyle(fontSize: 12, color: AppColors.success)),
                            ]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
