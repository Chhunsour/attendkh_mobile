import 'package:attendkh/l10n/app_localizations.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/company_announcements_repository.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/components/custom_date_picker.dart';

class AdminCompanyAnnouncementsScreen extends StatefulWidget {
  const AdminCompanyAnnouncementsScreen({super.key});

  @override
  State<AdminCompanyAnnouncementsScreen> createState() => _State();
}

class _State extends State<AdminCompanyAnnouncementsScreen> {
  bool _loading = true;
  List<CompanyAnnouncementData> _announcements = [];
  String _search = '';
  String _priority = 'all';
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _from = 0;
  int _to = 0;

  final CompanyAnnouncementsRepository _repo = CompanyAnnouncementsRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getAnnouncements(
        search: _search,
        priority: _priority,
        page: _currentPage,
      );
      setState(() {
        _announcements = res.announcements;
        _currentPage = res.currentPage;
        _lastPage = res.lastPage;
        _total = res.total;
        _from = res.from;
        _to = res.to;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _changePage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    setState(() => _currentPage = page);
    _fetchData();
  }

  int get _publishedCount =>
      _announcements.where((a) => a.isPublished).length;

  int get _urgentCount =>
      _announcements.where((a) => a.priority == 'urgent' || a.priority == 'high').length;

  int get _draftCount =>
      _announcements.where((a) => !a.isPublished).length;

  void _showForm([CompanyAnnouncementData? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final contentCtrl = TextEditingController(text: isEdit ? item.content : '');
    String priority = isEdit ? item.priority : 'normal';
    String audience = isEdit ? item.audience : 'all';
    String expiresAt = isEdit ? (item.expiresAt ?? '') : '';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Announcement' : 'New Announcement',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Title *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Annual Company Retreat 2026',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content
                        Text(
                          'Announcement Body *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contentCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write announcement details, schedule, or message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Priority Level
                        Text(
                          AppLocalizations.of(context)?.priority ?? 'Priority Level',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: priority,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(value: 'low', child: Text(AppLocalizations.of(context)?.low ?? 'Low Priority')),
                            DropdownMenuItem(value: 'normal', child: Text(AppLocalizations.of(context)?.normal ?? 'Normal Priority')),
                            DropdownMenuItem(value: 'high', child: Text(AppLocalizations.of(context)?.high ?? 'High Priority')),
                            DropdownMenuItem(value: 'urgent', child: Text(AppLocalizations.of(context)?.urgentBroadcast ?? 'Urgent Broadcast')),
                          ],
                          onChanged: (val) {
                            if (val != null) setSheetState(() => priority = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Audience
                        Text(
                          AppLocalizations.of(context)?.targetDepartment ?? 'Target Audience',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: audience,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)?.companyWide ?? 'Everyone (Company-Wide)')),
                            const DropdownMenuItem(value: 'managers', child: Text('Managers Only')),
                            const DropdownMenuItem(value: 'hr', child: Text('HR Department Only')),
                          ],
                          onChanged: (val) {
                            if (val != null) setSheetState(() => audience = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Expiration Date
                        Text(
                          'Expires At (Optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final initial = expiresAt.isNotEmpty
                                ? DateTime.tryParse(expiresAt) ?? DateTime.now().add(const Duration(days: 30))
                                : DateTime.now().add(const Duration(days: 30));
                            final picked = await showCustomDatePicker(
                              context,
                              initialDate: initial,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                expiresAt = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border(context)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  expiresAt.isNotEmpty ? expiresAt : 'No expiration date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: expiresAt.isNotEmpty
                                        ? AppColors.textPrimary(context)
                                        : AppColors.grey400,
                                  ),
                                ),
                                if (expiresAt.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setSheetState(() => expiresAt = ''),
                                    child: const Icon(Icons.clear, size: 18, color: AppColors.grey400),
                                  )
                                else
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.grey400),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: saving
                                ? null
                                : () async {
                                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter both title and content.'), backgroundColor: AppColors.danger),
                                      );
                                      return;
                                    }

                                    setSheetState(() => saving = true);
                                    try {
                                      final payload = {
                                        'title': titleCtrl.text.trim(),
                                        'content': contentCtrl.text.trim(),
                                        'priority': priority,
                                        'audience': audience,
                                        if (expiresAt.isNotEmpty) 'expires_at': expiresAt,
                                      };

                                      if (isEdit) {
                                        await _repo.updateAnnouncement(item.id, payload);
                                      } else {
                                        await _repo.createAnnouncement(payload);
                                      }

                                      Navigator.pop(ctx);
                                      _fetchData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isEdit ? '✅ Announcement updated' : '✅ Announcement created'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => saving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                                        );
                                      }
                                    }
                                  },
                            child: saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isEdit ? 'Update Announcement' : 'Create Announcement',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPreview(CompanyAnnouncementData a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Announcement Broadcast',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _priorityBadge(a.priority),
                        _audienceBadge(a.audience),
                        _statusBadge(a.isPublished),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(
                        a.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary(context),
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Author', a.authorName ?? 'Admin'),
                    if (a.createdAt != null)
                      _infoRow('Created', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(a.createdAt!) ?? DateTime.now())),
                    if (a.publishedAt != null)
                      _infoRow('Published', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(a.publishedAt!) ?? DateTime.now())),
                    if (a.expiresAt != null && a.expiresAt!.isNotEmpty)
                      _infoRow('Expires', DateFormat('dd MMM yyyy').format(DateTime.tryParse(a.expiresAt!) ?? DateTime.now())),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: a.isPublished ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  if (a.isPublished) {
                                    await _repo.unpublishAnnouncement(a.id);
                                  } else {
                                    await _repo.publishAnnouncement(a.id);
                                  }
                                  _fetchData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(a.isPublished ? 'Unpublished' : '✅ Published & notifications broadcasted'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                                    );
                                  }
                                }
                              },
                              icon: Icon(a.isPublished ? Icons.visibility_off_rounded : Icons.send_rounded, color: Colors.white, size: 16),
                              label: Text(
                                a.isPublished ? AppLocalizations.of(context)?.unpublish ?? 'Unpublish' : AppLocalizations.of(context)?.publish ?? 'Publish',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.border(context)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showForm(a);
                              },
                              icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF7C3AED)),
                              label: Text(
                                AppLocalizations.of(context)?.edit ?? 'Edit',
                                style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;

    switch (priority) {
      case 'urgent':
        textColor = const Color(0xFFE11D48);
        bgColor = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFFFE4E6);
        label = 'Urgent';
        break;
      case 'high':
        textColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFEF3C7);
        label = 'High';
        break;
      case 'normal':
        textColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFDBEAFE);
        label = 'Normal';
        break;
      default:
        textColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.3),
      ),
    );
  }

  Widget _audienceBadge(String audience) {
    final labels = {'all': 'Everyone', 'managers': 'Managers', 'hr': 'HR Only'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 10, color: Color(0xFF7C3AED)),
          const SizedBox(width: 3),
          Text(
            labels[audience] ?? audience,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isPublished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPublished ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 10,
            color: isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 3),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CompanyAnnouncementData a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Delete Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to delete "${a.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.deleteAnnouncement(a.id);
                _fetchData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Announcement deleted'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Announcements',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () => _showForm(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            // ── 1. Top Executive Banner ─────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7C3AED),
                      Color(0xFF6366F1),
                      Color(0xFF4F46E5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha:0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_total Announcements',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_publishedCount active · $_draftCount drafts',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha:0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Stats Bar
                    Row(
                      children: [
                        _buildHeaderPill('Total', '$_total'),
                        const SizedBox(width: 8),
                        _buildHeaderPill('Live', '$_publishedCount'),
                        const SizedBox(width: 8),
                        _buildHeaderPill('Urgent', '$_urgentCount'),
                        const SizedBox(width: 8),
                        _buildHeaderPill('Drafts', '$_draftCount'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Search & Priority Filter Chips ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                        decoration: InputDecoration(
                          hintText: 'Search announcements...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.grey400),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _search = '';
                                      _currentPage = 1;
                                    });
                                    _fetchData();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (val) {
                          setState(() {
                            _search = val.trim();
                            _currentPage = 1;
                          });
                          _fetchData();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Priority Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPriorityChip('all', 'All Priorities'),
                          const SizedBox(width: 8),
                          _buildPriorityChip('urgent', 'Urgent'),
                          const SizedBox(width: 8),
                          _buildPriorityChip('high', 'High'),
                          const SizedBox(width: 8),
                          _buildPriorityChip('normal', 'Normal'),
                          const SizedBox(width: 8),
                          _buildPriorityChip('low', 'Low'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── 3. Announcements List ───────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: LoadingIndicator(message: 'Loading Announcements...'),
                ),
              )
            else if (_announcements.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: const Icon(Icons.campaign_outlined, size: 36, color: AppColors.grey400),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No announcements found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap + to create your first announcement',
                        style: TextStyle(fontSize: 12, color: AppColors.grey400),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = _announcements[index];
                      return _buildAnnouncementCard(a);
                    },
                    childCount: _announcements.length,
                  ),
                ),
              ),

            // ── 4. Pagination Controls ──────────────────────────────────
            if (!_loading && _lastPage > 1)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing $_from-$_to of $_total',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                          ),
                          Text(
                            '$_currentPage / $_lastPage',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            onPressed: _currentPage < _lastPage ? () => _changePage(_currentPage + 1) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label) {
    final isSelected = _priority == key;
    return GestureDetector(
      onTap: () {
        if (_priority == key) return;
        setState(() {
          _priority = key;
          _currentPage = 1;
        });
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : AppColors.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha:0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(CompanyAnnouncementData a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPreview(a),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _priorityBadge(a.priority),
                        const SizedBox(width: 6),
                        _audienceBadge(a.audience),
                      ],
                    ),
                    _statusBadge(a.isPublished),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  a.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),

                // Content Snippet
                Text(
                  a.content,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Date & Author
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      a.authorName ?? 'Admin',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      a.createdAt != null
                          ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(a.createdAt!) ?? DateTime.now())
                          : '',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Action Bar (Compact & Overflow-Proof)
                Row(
                  children: [
                    // View Button
                    InkWell(
                      onTap: () => _showPreview(a),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF7C3AED)),
                            SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Publish / Unpublish Toggle Button
                    InkWell(
                      onTap: () async {
                        try {
                          if (a.isPublished) {
                            await _repo.unpublishAnnouncement(a.id);
                          } else {
                            await _repo.publishAnnouncement(a.id);
                          }
                          _fetchData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(a.isPublished ? 'Unpublished' : '✅ Published'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: a.isPublished
                              ? const Color(0xFFF59E0B).withValues(alpha:0.1)
                              : const Color(0xFF10B981).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              a.isPublished ? Icons.visibility_off_outlined : Icons.send_rounded,
                              size: 13,
                              color: a.isPublished ? const Color(0xFFD97706) : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              a.isPublished ? AppLocalizations.of(context)?.unpublish ?? 'Unpublish' : AppLocalizations.of(context)?.publish ?? 'Publish',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: a.isPublished ? const Color(0xFFD97706) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Edit Icon Button
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey500),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: AppLocalizations.of(context)?.edit ?? 'Edit',
                      onPressed: () => _showForm(a),
                    ),
                    const SizedBox(width: 14),

                    // Delete Icon Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: AppLocalizations.of(context)?.delete ?? 'Delete',
                      onPressed: () => _confirmDelete(a),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
