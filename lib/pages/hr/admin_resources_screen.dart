import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/announcements_repository.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

/// Admin screen for managing Shifts, Holidays, Announcements, Policies, Documents
class AdminResourcesScreen extends ConsumerStatefulWidget {
  const AdminResourcesScreen({super.key});

  @override
  ConsumerState<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends ConsumerState<AdminResourcesScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Resource Directory',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surfaceLight,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Shifts'),
                Tab(text: 'Holidays'),
                Tab(text: 'Announce.'),
                Tab(text: 'Policies'),
                Tab(text: 'Docs'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ShiftsTab(),
                _HolidaysTab(),
                _AnnouncementsTab(),
                _PoliciesTab(),
                _DocumentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shifts Tab ──────────────────────────────────────────────────────────────
class _ShiftsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsAdminProvider);
    return Stack(
      children: [
        shiftsAsync.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No shifts', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                      child: Row(
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.schedule, color: AppColors.secondary, size: 22)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text('${s.startTime} – ${s.endTime}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            if (s.employeesCount != null) Text('${s.employeesCount} employees', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                          ])),
                          IconButton(icon: const Icon(Icons.person_add, size: 20, color: AppColors.secondary), onPressed: () => _assignShift(context, ref, s.id)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteShift(context, ref, s.id, s.name)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading shifts...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(shiftsAdminProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(onPressed: () => _showCreateShiftDialog(context, ref), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }

  void _showCreateShiftDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '17:00');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Shift'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Morning Shift')),
          const SizedBox(height: 12),
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time', hintText: 'HH:MM')),
          const SizedBox(height: 12),
          TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time', hintText: 'HH:MM')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createShift(name: nameCtrl.text.trim(), startTime: startCtrl.text.trim(), endTime: endCtrl.text.trim());
              ref.invalidate(shiftsAdminProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shift created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  void _assignShift(BuildContext context, WidgetRef ref, int shiftId) {
    final empIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Shift'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (empIdCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().assignShift(shiftId, int.parse(empIdCtrl.text.trim()));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shift assigned'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Assign')),
        ],
      ),
    );
  }

  Future<void> _deleteShift(BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete shift "$name"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteShift(id);
        ref.invalidate(shiftsAdminProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shift deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

// ── Holidays Tab ────────────────────────────────────────────────────────────
class _HolidaysTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysAdminProvider);
    return Stack(
      children: [
        holidaysAsync.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No holidays', style: TextStyle(color: AppColors.grey400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final h = items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                      child: Row(
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.celebration, color: AppColors.success, size: 22)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text(h.date, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            if (h.isRecurring) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(4)), child: const Text('Recurring', style: TextStyle(fontSize: 10, color: AppColors.info))),
                          ])),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteHoliday(context, ref, h.id, h.name)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const LoadingIndicator(message: 'Loading holidays...'),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(holidaysAdminProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(onPressed: () => _showCreateHolidayDialog(context, ref), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }

  void _showCreateHolidayDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Holiday'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. New Year')),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date', hintText: 'YYYY-MM-DD')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createHoliday(name: nameCtrl.text.trim(), date: dateCtrl.text.trim());
              ref.invalidate(holidaysAdminProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Holiday created'), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _deleteHoliday(BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete holiday "$name"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteHoliday(id);
        ref.invalidate(holidaysAdminProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Holiday deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

// ── Announcements Tab ───────────────────────────────────────────────────────
class _AnnouncementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = AnnouncementsRepository();
    return FutureBuilder(
      future: repo.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator(message: 'Loading...');
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: const Text('Retry')));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No announcements', style: TextStyle(color: AppColors.grey400)));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = items[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)), child: const Text('Published', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success))),
                ]),
                if (a.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(a.content, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  IconButton(icon: const Icon(Icons.unpublished_outlined, size: 20, color: AppColors.warning), tooltip: 'Unpublish', onPressed: () => _togglePublish(context, ref, a.id, false)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), tooltip: 'Delete', onPressed: () => _deleteAnnouncement(context, ref, a.id, a.title)),
                ]),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _togglePublish(BuildContext context, WidgetRef ref, int id, bool publish) async {
    try {
      final repo = AdminOperationsRepository();
      if (publish) { await repo.publishAnnouncement(id); } else { await repo.unpublishAnnouncement(id); }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Announcement ${publish ? "published" : "unpublished"}'), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _deleteAnnouncement(BuildContext context, WidgetRef ref, int id, String title) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete "$title"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteDocument(id); // reuse generic delete
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}

// ── Policies Tab ────────────────────────────────────────────────────────────
class _PoliciesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = PoliciesRepository();
    return FutureBuilder(
      future: repo.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator(message: 'Loading...');
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: const Text('Retry')));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No policies', style: TextStyle(color: AppColors.grey400)));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = items[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.policy, color: AppColors.info, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(p.category, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColors.grey400, size: 20),
                    onSelected: (action) async {
                      final opsRepo = AdminOperationsRepository();
                      try {
                        if (action == 'publish') { await opsRepo.publishPolicy(p.id); }
                        else if (action == 'archive') { await opsRepo.archivePolicy(p.id); }
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Policy ${action}d'), backgroundColor: AppColors.success));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.publish, size: 18), SizedBox(width: 8), Text('Publish')])),
                      const PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive, size: 18), SizedBox(width: 8), Text('Archive')])),
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
}

// ── Documents Tab ───────────────────────────────────────────────────────────
class _DocumentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = DocumentsRepository();
    return FutureBuilder(
      future: repo.getDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator(message: 'Loading...');
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: const Text('Retry')));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No documents', style: TextStyle(color: AppColors.grey400)));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = items[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description, color: AppColors.warning, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (d.category != null) Text(d.category!, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                  ])),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteDoc(context, ref, d.id, d.name)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDoc(BuildContext context, WidgetRef ref, int id, String title) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text('Delete document "$title"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteDocument(id);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Document deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}