// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';

class AdminPoliciesScreen extends StatefulWidget {
  const AdminPoliciesScreen({super.key});

  @override
  State<AdminPoliciesScreen> createState() => _AdminPoliciesScreenState();
}

class _AdminPoliciesScreenState extends State<AdminPoliciesScreen> {
  bool _loading = true;
  List<Policy> _policies = [];
  List<DepartmentData> _departments = [];

  String _search = '';
  String _status = 'all';
  String _departmentId = 'all';
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _from = 0;
  int _to = 0;

  final PoliciesRepository _repo = PoliciesRepository();
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
      final res = await _repo.getAll(
        search: _search,
        status: _status,
        departmentId: _departmentId,
        page: _currentPage,
      );
      setState(() {
        _policies = res.policies;
        _departments = res.departments;
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
      _policies.where((p) => p.status == 'published').length;

  int get _reviewDueCount {
    final now = DateTime.now();
    return _policies.where((p) {
      if (p.reviewDate == null || p.reviewDate!.isEmpty) return false;
      final revDate = DateTime.tryParse(p.reviewDate!);
      if (revDate == null) return false;
      final diff = revDate.difference(now).inDays;
      return diff <= 30;
    }).length;
  }

  int get _draftCount =>
      _policies.where((p) => p.status == 'draft').length;

  void _showForm([Policy? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final contentCtrl = TextEditingController(text: isEdit ? item.content : '');
    final versionCtrl = TextEditingController(text: isEdit ? item.version : '1.0');
    String departmentId = isEdit ? (item.departmentId?.toString() ?? '') : '';
    String status = isEdit ? item.status : 'draft';
    String effectiveDate = isEdit ? (item.effectiveDate ?? '') : '';
    String reviewDate = isEdit ? (item.reviewDate ?? '') : '';
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
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF059669), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Edit Policy' : 'New Policy',
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

                // Body Form
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
                          'Policy Title *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Code of Conduct & Ethics',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Department
                        Text(
                          'Department Scope',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: departmentId.isEmpty ? '' : departmentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Company-Wide (All)')),
                            ..._departments.map(
                              (d) => DropdownMenuItem(
                                value: d.id.toString(),
                                child: Text(d.name),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setSheetState(() => departmentId = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Version & Status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Version *',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: versionCtrl,
                                    decoration: InputDecoration(
                                      hintText: '1.0',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppColors.border(context)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: status,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppColors.border(context)),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                                      DropdownMenuItem(value: 'published', child: Text('Published')),
                                      DropdownMenuItem(value: 'archived', child: Text('Archived')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setSheetState(() => status = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Effective Date & Review Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Effective Date',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showCustomDatePicker(
                                        context,
                                        initialDate: effectiveDate.isNotEmpty
                                            ? (DateTime.tryParse(effectiveDate) ?? DateTime.now())
                                            : DateTime.now(),
                                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                      );
                                      if (picked != null) {
                                        setSheetState(() => effectiveDate = DateFormat('yyyy-MM-dd').format(picked));
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border(context)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            effectiveDate.isNotEmpty ? effectiveDate : 'Select date',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: effectiveDate.isNotEmpty
                                                  ? AppColors.textPrimary(context)
                                                  : AppColors.grey400,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.grey400),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review Date',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showCustomDatePicker(
                                        context,
                                        initialDate: reviewDate.isNotEmpty
                                            ? (DateTime.tryParse(reviewDate) ?? DateTime.now().add(const Duration(days: 365)))
                                            : DateTime.now().add(const Duration(days: 365)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                      );
                                      if (picked != null) {
                                        setSheetState(() => reviewDate = DateFormat('yyyy-MM-dd').format(picked));
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border(context)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            reviewDate.isNotEmpty ? reviewDate : 'Select date',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: reviewDate.isNotEmpty
                                                  ? AppColors.textPrimary(context)
                                                  : AppColors.grey400,
                                            ),
                                          ),
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.grey400),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Content
                        Text(
                          'Policy Content *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contentCtrl,
                          maxLines: 6,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Write the complete policy terms, rules, and guidelines...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border(context)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
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
                                      if (isEdit) {
                                        await _repo.updatePolicy(
                                          item.id,
                                          title: titleCtrl.text.trim(),
                                          content: contentCtrl.text.trim(),
                                          version: versionCtrl.text.trim().isNotEmpty ? versionCtrl.text.trim() : '1.0',
                                          departmentId: departmentId.isNotEmpty ? departmentId : null,
                                          status: status,
                                          effectiveDate: effectiveDate.isNotEmpty ? effectiveDate : null,
                                          reviewDate: reviewDate.isNotEmpty ? reviewDate : null,
                                        );
                                      } else {
                                        await _repo.createPolicy(
                                          title: titleCtrl.text.trim(),
                                          content: contentCtrl.text.trim(),
                                          version: versionCtrl.text.trim().isNotEmpty ? versionCtrl.text.trim() : '1.0',
                                          departmentId: departmentId.isNotEmpty ? departmentId : null,
                                          status: status,
                                          effectiveDate: effectiveDate.isNotEmpty ? effectiveDate : null,
                                          reviewDate: reviewDate.isNotEmpty ? reviewDate : null,
                                        );
                                      }

                                      Navigator.pop(ctx);
                                      _fetchData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isEdit ? '✅ Policy updated' : '✅ Policy created'),
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
                                    isEdit ? 'Update Policy' : 'Save Policy Document',
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

  void _showPolicyReader(Policy p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
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
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF059669), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Policy Document',
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
                        _statusBadge(p.status),
                        _departmentBadge(p.department?.name),
                        _versionBadge(p.version),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      p.title,
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
                        p.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary(context),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Effective', p.effectiveDate ?? 'Pending'),
                    _infoRow('Review Due', p.reviewDate ?? 'N/A'),
                    _infoRow('Author', p.creatorName ?? 'System Admin'),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (p.status == 'draft')
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    await _repo.publishPolicy(p.id);
                                    _fetchData();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Policy Published'), backgroundColor: AppColors.success),
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
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                label: const Text('Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          )
                        else if (p.status == 'published')
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    await _repo.archivePolicy(p.id);
                                    _fetchData();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Policy Archived'), backgroundColor: AppColors.success),
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
                                icon: const Icon(Icons.archive_outlined, color: Colors.white, size: 16),
                                label: const Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                                _showForm(p);
                              },
                              icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF059669)),
                              label: const Text(
                                'Edit',
                                style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _versionBadge(String version) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        'v$version',
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.grey600),
      ),
    );
  }

  Widget _departmentBadge(String? departmentName) {
    final name = departmentName ?? 'Company-Wide';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.corporate_fare_rounded, size: 10, color: Color(0xFF059669)),
          const SizedBox(width: 3),
          Text(
            name,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;
    IconData icon;

    switch (status) {
      case 'published':
        textColor = const Color(0xFF059669);
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        label = 'Published';
        icon = Icons.check_circle_rounded;
        break;
      case 'archived':
        textColor = const Color(0xFF64748B);
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        label = 'Archived';
        icon = Icons.archive_outlined;
        break;
      default:
        textColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        label = 'Draft';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Policy p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Delete Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to delete "${p.title}" permanently?'),
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
                await _repo.deletePolicy(p.id);
                _fetchData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Policy deleted'), backgroundColor: AppColors.success),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          'Policies',
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
                backgroundColor: const Color(0xFF059669),
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
                      Color(0xFF059669),
                      Color(0xFF0D9488),
                      Color(0xFF0F766E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.28),
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
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
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
                                '$_total Company Policies',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_publishedCount active · $_reviewDueCount review due',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
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
                        _buildHeaderPill('Active', '$_publishedCount'),
                        const SizedBox(width: 8),
                        _buildHeaderPill('Due', '$_reviewDueCount'),
                        const SizedBox(width: 8),
                        _buildHeaderPill('Drafts', '$_draftCount'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Search & Status / Dept Filter Chips ──────────────────
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
                          hintText: 'Search policies...',
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

                    // Status Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusChip('all', 'All Status'),
                          const SizedBox(width: 8),
                          _buildStatusChip('published', 'Published'),
                          const SizedBox(width: 8),
                          _buildStatusChip('draft', 'Draft'),
                          const SizedBox(width: 8),
                          _buildStatusChip('archived', 'Archived'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Department Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDeptChip('all', 'All Departments'),
                          const SizedBox(width: 8),
                          _buildDeptChip('company-wide', 'Company-Wide'),
                          ..._departments.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildDeptChip(d.id.toString(), d.name),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── 3. Policies List ────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: LoadingIndicator(message: 'Loading Policies...'),
                ),
              )
            else if (_policies.isEmpty)
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
                        child: const Icon(Icons.menu_book_outlined, size: 36, color: AppColors.grey400),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No policies found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap + to create your first policy document',
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
                      final p = _policies[index];
                      return _buildPolicyCard(p);
                    },
                    childCount: _policies.length,
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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
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

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _status == key;
    return GestureDetector(
      onTap: () {
        if (_status == key) return;
        setState(() {
          _status = key;
          _currentPage = 1;
        });
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : AppColors.border(context),
          ),
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

  Widget _buildDeptChip(String key, String label) {
    final isSelected = _departmentId == key;
    return GestureDetector(
      onTap: () {
        if (_departmentId == key) return;
        setState(() {
          _departmentId = key;
          _currentPage = 1;
        });
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669).withValues(alpha: 0.12) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF059669) : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard(Policy p) {
    final isReviewDue = () {
      if (p.reviewDate == null || p.reviewDate!.isEmpty) return false;
      final rev = DateTime.tryParse(p.reviewDate!);
      if (rev == null) return false;
      return rev.difference(DateTime.now()).inDays <= 30;
    }();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          onTap: () => _showPolicyReader(p),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Badges Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _statusBadge(p.status),
                        const SizedBox(width: 6),
                        _departmentBadge(p.department?.name),
                      ],
                    ),
                    _versionBadge(p.version),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  p.title,
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
                  p.content,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Metadata Row (Effective Date & Review Warning)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(
                      p.effectiveDate != null && p.effectiveDate!.isNotEmpty
                          ? 'Eff: ${DateFormat('dd MMM yyyy').format(DateTime.tryParse(p.effectiveDate!) ?? DateTime.now())}'
                          : 'Pending',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.grey500, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    if (isReviewDue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              'Review Due',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
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
                      onTap: () => _showPolicyReader(p),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'Read',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Publish / Archive Toggle Button
                    if (p.status == 'draft')
                      InkWell(
                        onTap: () async {
                          try {
                            await _repo.publishPolicy(p.id);
                            _fetchData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Policy Published'), backgroundColor: AppColors.success),
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
                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, size: 13, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text(
                                'Publish',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (p.status == 'published')
                      InkWell(
                        onTap: () async {
                          try {
                            await _repo.archivePolicy(p.id);
                            _fetchData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Policy Archived'), backgroundColor: AppColors.success),
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
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.archive_outlined, size: 13, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text(
                                'Archive',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
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
                      tooltip: 'Edit',
                      onPressed: () => _showForm(p),
                    ),
                    const SizedBox(width: 14),

                    // Delete Icon Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(p),
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
