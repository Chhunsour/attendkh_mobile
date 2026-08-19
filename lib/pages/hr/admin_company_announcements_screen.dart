// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/company_announcements_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  void _showForm([CompanyAnnouncementData? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final contentCtrl = TextEditingController(text: isEdit ? item.content : '');
    String priority = isEdit ? item.priority : 'normal';
    String audience = isEdit ? item.audience : 'all';
    String expiresAt = isEdit ? (item.expiresAt ?? '') : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.textPrimary(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Announcement' : 'New Announcement',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: contentCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Content *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (val) => setSheetState(() => priority = val ?? 'normal'),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: audience,
                      decoration: InputDecoration(
                        labelText: 'Audience',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Everyone')),
                        DropdownMenuItem(value: 'managers', child: Text('Managers')),
                        DropdownMenuItem(value: 'hr', child: Text('HR Only')),
                      ],
                      onChanged: (val) => setSheetState(() => audience = val ?? 'all'),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final initial = expiresAt.isNotEmpty
                            ? (DateTime.tryParse(expiresAt) ?? DateTime.now())
                            : DateTime.now().add(const Duration(days: 7));
                        final picked = await showCustomDatePicker(
                          context,
                          initialDate: initial,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() => expiresAt = DateFormat('yyyy-MM-dd').format(picked));
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Expires At', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                const SizedBox(height: 4),
                                Text(
                                  expiresAt.isNotEmpty
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(expiresAt))
                                      : 'No expiration (Optional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: expiresAt.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                    color: expiresAt.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (expiresAt.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setSheetState(() => expiresAt = ''),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.close_rounded, color: AppColors.grey400, size: 18),
                                    ),
                                  ),
                                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields', style: TextStyle(color: Colors.white)),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          try {
                            final data = {
                              'title': titleCtrl.text.trim(),
                              'content': contentCtrl.text.trim(),
                              'priority': priority,
                              'audience': audience,
                              if (expiresAt.isNotEmpty) 'expires_at': expiresAt,
                            };
                            if (isEdit) {
                              await _repo.updateAnnouncement(item.id, data);
                            } else {
                              await _repo.createAnnouncement(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
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
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                        child: Text(
                          isEdit ? 'Update Announcement' : 'Create Announcement',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text('Announcement Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.grey400),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _priorityBadge(a.priority),
                        _audienceBadge(a.audience),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: a.isPublished ? AppColors.successLight : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            a.isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: a.isPublished ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(a.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Text(a.content, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context), height: 1.5)),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Author', a.authorName ?? 'Unknown'),
                    if (a.createdAt != null) _infoRow('Created', a.createdAt!.substring(0, 10)),
                    if (a.publishedAt != null) _infoRow('Published', a.publishedAt!.substring(0, 10)),
                    if (a.expiresAt != null && a.expiresAt!.isNotEmpty)
                      _infoRow('Expires', DateFormat('dd MMM yyyy').format(DateTime.parse(a.expiresAt!))),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: a.isPublished ? AppColors.warning : AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                        content: Text(a.isPublished ? 'Unpublished' : '✅ Published & notifications sent'),
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
                              icon: Icon(a.isPublished ? Icons.visibility_off : Icons.send, color: Colors.white, size: 18),
                              label: Text(a.isPublished ? 'Unpublish' : 'Publish', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showForm(a);
                              },
                              icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                              label: const Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)))),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final config = {
      'urgent': {'color': AppColors.danger, 'bg': AppColors.dangerLight, 'label': 'Urgent'},
      'high': {'color': AppColors.primary, 'bg': AppColors.primaryLight, 'label': 'High'},
      'normal': {'color': const Color(0xFF2563EB), 'bg': const Color(0xFFEFF6FF), 'label': 'Normal'},
      'low': {'color': AppColors.grey500, 'bg': AppColors.backgroundLight, 'label': 'Low'},
    };
    final c = config[priority] ?? config['normal']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c['bg'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        c['label'] as String,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c['color'] as Color),
      ),
    );
  }

  Widget _audienceBadge(String audience) {
    final labels = {'all': 'Everyone', 'managers': 'Managers', 'hr': 'HR Only'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        labels[audience] ?? audience,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
      ),
    );
  }

  void _confirmDelete(CompanyAnnouncementData a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "${a.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.deleteAnnouncement(a.id);
                _fetchData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Deleted'), backgroundColor: AppColors.success),
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
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
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
        title: Text('Announcements', style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.add, color: AppColors.primary), onPressed: () => _showForm()),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search announcements...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    _search = val;
                    _currentPage = 1;
                    _fetchData();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _priority,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _priority = val;
                      _currentPage = 1;
                      _fetchData();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? LoadingIndicator(message: 'Loading Announcements...')
                : _announcements.isEmpty
                    ? Center(child: Text('No announcements found.', style: TextStyle(color: AppColors.grey500)))
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final a = _announcements[i];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _priorityBadge(a.priority),
                                        const SizedBox(width: 8),
                                        _audienceBadge(a.audience),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: a.isPublished ? AppColors.successLight : AppColors.warningLight,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            a.isPublished ? 'Published' : 'Draft',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: a.isPublished ? AppColors.success : AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.grey400, size: 20),
                                      onSelected: (action) {
                                        if (action == 'view') {
                                          _showPreview(a);
                                        } else if (action == 'edit') {
                                          _showForm(a);
                                        } else if (action == 'publish') {
                                          _repo.publishAnnouncement(a.id).then((_) {
                                            _fetchData();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('✅ Published'), backgroundColor: AppColors.success),
                                            );
                                          }).catchError((e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                                            );
                                          });
                                        } else if (action == 'unpublish') {
                                          _repo.unpublishAnnouncement(a.id).then((_) {
                                            _fetchData();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Unpublished'), backgroundColor: AppColors.success),
                                            );
                                          }).catchError((e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                                            );
                                          });
                                        } else if (action == 'delete') {
                                          _confirmDelete(a);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
                                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                                        if (!a.isPublished)
                                          const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.send, size: 18), SizedBox(width: 8), Text('Publish')]))
                                        else
                                          const PopupMenuItem(value: 'unpublish', child: Row(children: [Icon(Icons.visibility_off, size: 18), SizedBox(width: 8), Text('Unpublish')])),
                                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.danger))])),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  a.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a.content,
                                  style: const TextStyle(color: AppColors.grey500, fontSize: 13, height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${a.authorName ?? 'Unknown'} · ${a.createdAt?.substring(0, 10) ?? ''}',
                                  style: TextStyle(fontSize: 12, color: AppColors.grey400),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (_lastPage > 1)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.textPrimary(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Showing $_from-$_to of $_total', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: AppColors.grey600),
                        onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                      ),
                      Text('$_currentPage / $_lastPage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.grey600),
                        onPressed: _currentPage < _lastPage ? () => _changePage(_currentPage + 1) : null,
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
}
