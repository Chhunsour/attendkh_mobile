// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/admin_announcements_repository.dart';
import 'package:attendkh/l10n/app_localizations.dart';

final adminAnnouncementsProvider =
    FutureProvider.autoDispose<List<AdminAnnouncement>>((ref) {
      return AdminAnnouncementsRepository().getAnnouncements();
    });

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePublishStatus(AdminAnnouncement announcement) async {
    try {
      final updatedData = {
        'title': announcement.title,
        'content': announcement.body,
        'priority': announcement.priority,
        'audience': announcement.audience,
        'is_published': !announcement.isPublished,
      };

      await AdminAnnouncementsRepository().updateAnnouncement(announcement.id, updatedData);
      ref.invalidate(adminAnnouncementsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !announcement.isPublished
                  ? 'Announcement published & broadcasted!'
                  : 'Announcement unpublished (moved to drafts)',
            ),
            backgroundColor: !announcement.isPublished ? AppColors.success : AppColors.grey700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(adminAnnouncementsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.platformAnnouncementsTitle,
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
            onPressed: () => ref.invalidate(adminAnnouncementsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.campaign_rounded, size: 20),
        label: const Text(
          'Broadcast',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminAnnouncementsProvider),
        child: announcementsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(err, l10n),
          data: (list) => _buildContent(list, l10n),
        ),
      ),
    );
  }

  Widget _buildError(Object err, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadAnnouncements,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminAnnouncementsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<AdminAnnouncement> announcements,
    AppLocalizations l10n,
  ) {
    final publishedCount = announcements.where((a) => a.isPublished).length;
    final draftCount = announcements.where((a) => !a.isPublished).length;
    final urgentCount = announcements.where((a) => a.priority == 'urgent' || a.priority == 'high').length;

    var filtered = announcements.where((a) {
      final matchesSearch =
          a.title.toLowerCase().contains(_searchTerm) ||
          a.body.toLowerCase().contains(_searchTerm);
      
      bool matchesStatus = true;
      if (_statusFilter == 'published') {
        matchesStatus = a.isPublished;
      } else if (_statusFilter == 'draft') {
        matchesStatus = !a.isPublished;
      } else if (_statusFilter == 'urgent') {
        matchesStatus = (a.priority == 'urgent' || a.priority == 'high');
      } else if (_statusFilter == 'owners') {
        matchesStatus = (a.audience == 'owners');
      }

      return matchesSearch && matchesStatus;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // ── Overview Metric Cards ──
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Broadcasts',
                value: '${announcements.length}',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Published',
                value: '$publishedCount',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Drafts',
                value: '$draftCount',
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Urgent',
                value: '$urgentCount',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
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
              hintText: 'Search announcements...',
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

        // ── Status Filter Chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All (${announcements.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Published ($publishedCount)', 'published'),
              const SizedBox(width: 8),
              _buildFilterChip('Drafts ($draftCount)', 'draft'),
              const SizedBox(width: 8),
              _buildFilterChip('Urgent ($urgentCount)', 'urgent'),
              const SizedBox(width: 8),
              _buildFilterChip('👑 Owners', 'owners'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List of Announcements ──
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
                const Icon(Icons.campaign_outlined, size: 48, color: AppColors.grey300),
                const SizedBox(height: 12),
                Text(
                  _searchTerm.isNotEmpty ? 'No announcements matching "$_searchTerm"' : l10n.noAnnouncementsYet,
                  style: const TextStyle(color: AppColors.grey600, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.map((a) => _buildAnnouncementCard(a, l10n)),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
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
                  fontSize: 10,
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
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : AppColors.grey200),
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

  Widget _buildAnnouncementCard(
    AdminAnnouncement a,
    AppLocalizations l10n,
  ) {
    final priorityColor = switch (a.priority) {
      'urgent' => const Color(0xFFEF4444),
      'high' => const Color(0xFFF59E0B),
      'low' => const Color(0xFF64748B),
      _ => const Color(0xFF10B981),
    };

    final priorityLabel = switch (a.priority) {
      'urgent' => '🔴 Urgent',
      'high' => '🟡 High',
      'low' => '🔵 Low',
      _ => '🟢 Normal',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a.priority == 'urgent' ? const Color(0xFFEF4444).withValues(alpha: 0.3) : AppColors.border(context),
        ),
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
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Audience Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (a.audience == 'owners' ? const Color(0xFF8B5CF6) : const Color(0xFF0EA5E9)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.audience == 'owners' ? '👑 Owners Only' : '🌐 All Users',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: a.audience == 'owners' ? const Color(0xFF8B5CF6) : const Color(0xFF0284C7),
                  ),
                ),
              ),

              const Spacer(),

              // Quick Publish / Draft Switch
              GestureDetector(
                onTap: () => _togglePublishStatus(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: (a.isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 5.5,
                        color: a.isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: a.isPublished ? const Color(0xFF047857) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 4),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.surface(context),
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.grey500,
                  size: 20,
                ),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showCreateEditDialog(announcement: a);
                  } else if (action == 'toggle') {
                    _togglePublishStatus(a);
                  } else if (action == 'delete') {
                    _confirmDelete(a);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 17, color: Color(0xFF0EA5E9)),
                        const SizedBox(width: 10),
                        Text(
                          l10n.actionEdit,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          a.isPublished ? Icons.unpublished_outlined : Icons.publish_rounded,
                          size: 17,
                          color: a.isPublished ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          a.isPublished ? 'Unpublish (Draft)' : 'Publish Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Text(
                          l10n.btnDelete,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.body,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.grey600,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminAnnouncement announcement) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAnnouncementTitle),
        content: Text(l10n.deleteAnnouncementConfirm(announcement.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.btnDelete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminAnnouncementsRepository().deleteAnnouncement(announcement.id);
        ref.invalidate(adminAnnouncementsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.announcementDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.failedToLoadAnnouncements}: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showCreateEditDialog({AdminAnnouncement? announcement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnnouncementFormSheet(announcement: announcement, ref: ref),
    );
  }
}

class _AnnouncementFormSheet extends ConsumerStatefulWidget {
  final AdminAnnouncement? announcement;
  final WidgetRef ref;

  const _AnnouncementFormSheet({this.announcement, required this.ref});

  @override
  ConsumerState<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends ConsumerState<_AnnouncementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  String _priority = 'normal';
  String _audience = 'all';
  bool _isPublished = false;
  bool _isSaving = false;

  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _bodyCtrl = TextEditingController(text: a?.body ?? '');
    _priority = a?.priority ?? 'normal';
    _audience = a?.audience ?? 'all';
    _isPublished = a?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'content': _bodyCtrl.text.trim(),
        'priority': _priority,
        'audience': _audience,
        'is_published': _isPublished,
      };

      final repo = AdminAnnouncementsRepository();
      if (_isEditing) {
        await repo.updateAnnouncement(widget.announcement!.id, data);
      } else {
        await repo.createAnnouncement(data);
      }

      widget.ref.invalidate(adminAnnouncementsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? l10n.announcementUpdatedSuccess : l10n.announcementCreatedSuccess,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final isSelected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceChip(String label, String value, IconData icon) {
    final isSelected = _audience == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _audience = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0EA5E9).withValues(alpha: 0.12) : AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0EA5E9) : AppColors.border(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? const Color(0xFF0EA5E9) : AppColors.grey500),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0EA5E9) : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? l10n.editAnnouncementTitle : l10n.createAnnouncementTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.grey500),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                    decoration: _inputDecoration(l10n.titleLabel),
                  ),
                  const SizedBox(height: 12),

                  // Priority Level Selector
                  const Text(
                    'Priority Level',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildPriorityChip('Normal', 'normal', const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _buildPriorityChip('High', 'high', const Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      _buildPriorityChip('Urgent', 'urgent', const Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      _buildPriorityChip('Low', 'low', const Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target Audience Selector
                  const Text(
                    'Target Audience',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildAudienceChip('All Users', 'all', Icons.public_rounded),
                      const SizedBox(width: 8),
                      _buildAudienceChip('Owners Only', 'owners', Icons.workspace_premium_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                    decoration: _inputDecoration(l10n.bodyLabel),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.publishImmediatelyLabel,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        Switch(
                          value: _isPublished,
                          activeThumbColor: const Color(0xFF0EA5E9),
                          onChanged: (v) => setState(() => _isPublished = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _isEditing ? l10n.btnUpdateAnnouncement : l10n.btnCreateAnnouncement,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
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
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      filled: true,
      fillColor: AppColors.grey50,
    );
  }
}
