import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/announcements_repository.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.resourceDirectoryTitle,
          style: const TextStyle(
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
              tabs: [
                Tab(text: l10n.tabShifts),
                Tab(text: l10n.tabHolidays),
                Tab(text: l10n.tabAnnouncements),
                Tab(text: l10n.tabPolicies),
                Tab(text: l10n.tabDocs),
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
    final l10n = AppLocalizations.of(context)!;
    final shiftsAsync = ref.watch(shiftsAdminProvider);
    return Stack(
      children: [
        shiftsAsync.when(
          data: (items) => items.isEmpty
              ? Center(child: Text(l10n.noShifts, style: const TextStyle(color: AppColors.grey400)))
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
                            if (s.employeesCount != null) Text(l10n.permissionsCount(s.employeesCount!), style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                          ])),
                          IconButton(icon: const Icon(Icons.person_add, size: 20, color: AppColors.secondary), onPressed: () => _assignShift(context, ref, s.id)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteShift(context, ref, s.id, s.name)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => LoadingIndicator(message: l10n.loadingShifts),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(shiftsAdminProvider), icon: const Icon(Icons.refresh), label: Text(l10n.retry))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(onPressed: () => _showCreateShiftDialog(context, ref), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }

  void _showCreateShiftDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '17:00');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addShiftTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.shiftNameLabel, hintText: l10n.shiftNameHint)),
          const SizedBox(height: 12),
          TextField(controller: startCtrl, decoration: InputDecoration(labelText: l10n.startTimeLabel, hintText: 'HH:MM')),
          const SizedBox(height: 12),
          TextField(controller: endCtrl, decoration: InputDecoration(labelText: l10n.endTimeLabel, hintText: 'HH:MM')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().createShift(name: nameCtrl.text.trim(), startTime: startCtrl.text.trim(), endTime: endCtrl.text.trim());
              ref.invalidate(shiftsAdminProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shiftCreatedSuccess), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: Text(l10n.createBtn)),
        ],
      ),
    );
  }

  void _assignShift(BuildContext context, WidgetRef ref, int shiftId) {
    final l10n = AppLocalizations.of(context)!;
    final empIdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assignShiftTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: empIdCtrl, decoration: InputDecoration(labelText: l10n.employeeIdLabel), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () async {
            if (empIdCtrl.text.trim().isEmpty) return;
            try {
              await AdminOperationsRepository().assignShift(shiftId, int.parse(empIdCtrl.text.trim()));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shiftAssignedSuccess), backgroundColor: AppColors.success));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
            }
          }, child: Text(l10n.assignBtn)),
        ],
      ),
    );
  }

  Future<void> _deleteShift(BuildContext context, WidgetRef ref, int id, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text(l10n.deleteShiftConfirm(name)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteBtn, style: const TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteShift(id);
        ref.invalidate(shiftsAdminProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shiftDeletedSuccess(name)), backgroundColor: AppColors.success));
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
    final l10n = AppLocalizations.of(context)!;
    final holidaysAsync = ref.watch(holidaysAdminProvider);
    return Stack(
      children: [
        holidaysAsync.when(
          data: (items) => items.isEmpty
              ? Center(child: Text(l10n.noHolidays, style: const TextStyle(color: AppColors.grey400)))
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
                            if (h.isRecurring) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(4)), child: Text(l10n.recurringBadge, style: const TextStyle(fontSize: 10, color: AppColors.info))),
                          ])),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteHoliday(context, ref, h.id, h.name)),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => LoadingIndicator(message: l10n.loadingHolidays),
          error: (e, _) => Center(child: OutlinedButton.icon(onPressed: () => ref.invalidate(holidaysAdminProvider), icon: const Icon(Icons.refresh), label: Text(l10n.retry))),
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(onPressed: () => _showCreateHolidayDialog(context, ref), backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }

  void _showCreateHolidayDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toString().substring(0, 10));
    String selectedType = 'company';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.addHolidayTitle),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.shiftNameLabel, hintText: 'e.g. New Year')),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(labelText: l10n.holidayDateLabel, hintText: 'YYYY-MM-DD', suffixIcon: const Icon(Icons.calendar_today)),
              onTap: () async {
                final initDate = DateTime.tryParse(dateCtrl.text) ?? DateTime.now().add(const Duration(days: 1));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  dateCtrl.text = picked.toString().substring(0, 10);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: InputDecoration(labelText: l10n.holidayTypeLabel),
              items: [
                DropdownMenuItem(value: 'company', child: Text(l10n.holidayTypeCompany)),
                DropdownMenuItem(value: 'national', child: Text(l10n.holidayTypeNational)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedType = val);
              },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              try {
                await AdminOperationsRepository().createHoliday(name: nameCtrl.text.trim(), date: dateCtrl.text.trim(), type: selectedType);
                ref.invalidate(holidaysAdminProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.holidayCreatedSuccess), backgroundColor: AppColors.success));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
              }
            }, child: Text(l10n.createBtn)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHoliday(BuildContext context, WidgetRef ref, int id, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text(l10n.deleteHolidayConfirmSimple(name)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteBtn, style: const TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteHoliday(id);
        ref.invalidate(holidaysAdminProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.holidayDeletedSuccess), backgroundColor: AppColors.success));
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
    final l10n = AppLocalizations.of(context)!;
    final repo = AnnouncementsRepository();
    return FutureBuilder(
      future: repo.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return LoadingIndicator(message: l10n.loadingLabel);
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: Text(l10n.retry)));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return Center(child: Text(l10n.noAnnouncements, style: const TextStyle(color: AppColors.grey400)));
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
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)), child: Text(l10n.publishedStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success))),
                ]),
                if (a.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(a.content, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  IconButton(icon: const Icon(Icons.unpublished_outlined, size: 20, color: AppColors.warning), tooltip: l10n.unpublishBtn, onPressed: () => _togglePublish(context, ref, a.id, false)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), tooltip: l10n.deleteBtn, onPressed: () => _deleteAnnouncement(context, ref, a.id, a.title)),
                ]),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _togglePublish(BuildContext context, WidgetRef ref, int id, bool publish) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = AdminOperationsRepository();
      if (publish) { await repo.publishAnnouncement(id); } else { await repo.unpublishAnnouncement(id); }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publish ? l10n.announcementPublished : l10n.announcementUnpublished), backgroundColor: AppColors.success));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _deleteAnnouncement(BuildContext context, WidgetRef ref, int id, String title) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(l10n.deleteTitle), content: Text(l10n.deleteAnnouncementConfirm(title)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteBtn, style: const TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteDocument(id); // reuse generic delete
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deletedSuccess), backgroundColor: AppColors.success));
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
    final l10n = AppLocalizations.of(context)!;
    final repo = PoliciesRepository();
    return FutureBuilder(
      future: repo.getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return LoadingIndicator(message: l10n.loadingLabel);
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: Text(l10n.retry)));
        final items = snapshot.data?.policies ?? [];
        if (items.isEmpty) return Center(child: Text(l10n.noPolicies, style: const TextStyle(color: AppColors.grey400)));
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
                    Text(p.department?.name ?? l10n.companyWide, style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColors.grey400, size: 20),
                    onSelected: (action) async {
                      try {
                        if (action == 'publish') { await repo.publishPolicy(p.id); }
                        else if (action == 'archive') { await repo.archivePolicy(p.id); }
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.operationSuccess), backgroundColor: AppColors.success));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'publish', child: Row(children: [const Icon(Icons.publish, size: 18), const SizedBox(width: 8), Text(l10n.publishBtn)])),
                      PopupMenuItem(value: 'archive', child: Row(children: [const Icon(Icons.archive, size: 18), const SizedBox(width: 8), Text(l10n.archiveBtn)])),
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
    final l10n = AppLocalizations.of(context)!;
    final repo = DocumentsRepository();
    return FutureBuilder(
      future: repo.getDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return LoadingIndicator(message: l10n.loadingLabel);
        if (snapshot.hasError) return Center(child: OutlinedButton.icon(onPressed: () => (context as Element).markNeedsBuild(), icon: const Icon(Icons.refresh), label: Text(l10n.retry)));
        final items = snapshot.data?.documents ?? [];
        if (items.isEmpty) return Center(child: Text(l10n.noDocuments, style: const TextStyle(color: AppColors.grey400)));
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (d.department != null) Text(d.department!.name, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                        if (d.fileSize != null) Text(l10n.fileSizeLabel(d.fileSize.toString()), style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger), onPressed: () => _deleteDoc(context, ref, d.id, d.title)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDoc(BuildContext context, WidgetRef ref, int id, String title) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete'), content: Text(l10n.deleteDocumentConfirm(title)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteBtn, style: const TextStyle(color: AppColors.danger)))]));
    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteDocument(id);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.documentDeletedSuccess), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}