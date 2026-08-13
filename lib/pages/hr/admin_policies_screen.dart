import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
  String _sort = 'created_at';
  String _order = 'desc';

  final PoliciesRepository _repo = PoliciesRepository();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getAll(
        search: _search,
        status: _status,
        departmentId: _departmentId,
        page: _currentPage,
        sort: _sort,
        order: _order,
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

  void _toggleSort(String column) {
    setState(() {
      if (_sort == column) {
        _order = _order == 'asc' ? 'desc' : 'asc';
      } else {
        _sort = column;
        _order = 'asc';
      }
      _currentPage = 1;
    });
    _fetchData();
  }

  void _showForm([Policy? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final contentCtrl = TextEditingController(text: isEdit ? item.content : '');
    final versionCtrl = TextEditingController(
      text: isEdit ? item.version : '1.0',
    );
    final effCtrl = TextEditingController(
      text: isEdit ? (item.effectiveDate ?? '') : '',
    );
    final revCtrl = TextEditingController(
      text: isEdit ? (item.reviewDate ?? '') : '',
    );
    String selectedDeptId = isEdit ? (item.departmentId?.toString() ?? '') : '';
    String selectedStatus = isEdit ? item.status : 'draft';
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? l10n.editPolicy : l10n.createPolicy,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.policyTitleLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedDeptId.isEmpty
                                ? null
                                : selectedDeptId,
                            decoration: InputDecoration(
                              labelText: l10n.departmentLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(l10n.companyWide),
                              ),
                              ..._departments.map(
                                (d) => DropdownMenuItem(
                                  value: d.id.toString(),
                                  child: Text(d.name),
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setSheetState(() => selectedDeptId = val ?? ''),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedStatus,
                            decoration: InputDecoration(
                              labelText: l10n.statusLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'draft',
                                child: Text(l10n.statusDraft),
                              ),
                              DropdownMenuItem(
                                value: 'published',
                                child: Text(l10n.statusPublished),
                              ),
                              DropdownMenuItem(
                                value: 'archived',
                                child: Text(l10n.statusArchived),
                              ),
                            ],
                            onChanged: (val) => setSheetState(
                              () => selectedStatus = val ?? 'draft',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: versionCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.versionLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final initial = effCtrl.text.isNotEmpty
                                  ? (DateTime.tryParse(effCtrl.text) ??
                                        DateTime.now())
                                  : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: initial,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(
                                  () => effCtrl.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(picked),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      effCtrl.text.isNotEmpty
                                          ? DateFormat('dd MMM yyyy').format(
                                              DateTime.parse(effCtrl.text),
                                            )
                                          : l10n.effectiveDateLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: effCtrl.text.isNotEmpty
                                            ? FontWeight.bold
                                            : FontWeight.w400,
                                        color: effCtrl.text.isNotEmpty
                                            ? AppColors.grey900
                                            : AppColors.grey400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        final initial = revCtrl.text.isNotEmpty
                            ? (DateTime.tryParse(revCtrl.text) ??
                                  DateTime.now())
                            : DateTime.now();
                        final picked = await showCustomDatePicker(
                          context,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(
                            () => revCtrl.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(picked),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              revCtrl.text.isNotEmpty
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(DateTime.parse(revCtrl.text))
                                  : l10n.nextReviewDateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: revCtrl.text.isNotEmpty
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                                color: revCtrl.text.isNotEmpty
                                    ? AppColors.grey900
                                    : AppColors.grey400,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: contentCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.contentLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 5,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              contentCtrl.text.trim().isEmpty ||
                              versionCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.pleaseFillRequired,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          try {
                            if (isEdit) {
                              await _repo.updatePolicy(
                                item.id,
                                title: titleCtrl.text.trim(),
                                content: contentCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty
                                    ? null
                                    : selectedDeptId,
                                version: versionCtrl.text.trim(),
                                status: selectedStatus,
                                effectiveDate: effCtrl.text.trim().isEmpty
                                    ? null
                                    : effCtrl.text.trim(),
                                reviewDate: revCtrl.text.trim().isEmpty
                                    ? null
                                    : revCtrl.text.trim(),
                              );
                            } else {
                              await _repo.createPolicy(
                                title: titleCtrl.text.trim(),
                                content: contentCtrl.text.trim(),
                                departmentId: selectedDeptId.isEmpty
                                    ? null
                                    : selectedDeptId,
                                version: versionCtrl.text.trim(),
                                status: selectedStatus,
                                effectiveDate: effCtrl.text.trim().isEmpty
                                    ? null
                                    : effCtrl.text.trim(),
                                reviewDate: revCtrl.text.trim().isEmpty
                                    ? null
                                    : revCtrl.text.trim(),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isEdit ? l10n.updatePolicyBtn : l10n.createPolicyBtn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  void _showDetail(Policy p) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.department?.name ?? l10n.companyWide,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v${p.version}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (p.creatorName != null)
              Text(
                'Author: ${p.creatorName}',
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            if (p.effectiveDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l10n.effectiveDateLabel}: ${p.effectiveDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            if (p.reviewDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l10n.nextReviewDateLabel}: ${p.reviewDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Text(
                    p.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.grey800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, String title) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text(l10n.deletePolicyConfirm(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _repo.deletePolicy(id);
                _fetchData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.deleteBtn,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _changeStatus(int id, String action) async {
    try {
      if (action == 'publish') {
        await _repo.publishPolicy(id);
        // ignore: curly_braces_in_flow_control_structures
      } else if (action == 'archive')
        // ignore: curly_braces_in_flow_control_structures
        await _repo.archivePolicy(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Policy ${action}ed'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Policies',
          style: TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchPoliciesHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (val) {
                    _search = val;
                    _fetchData();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _status,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(l10n.allStatus),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text(l10n.statusDraft),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text(l10n.statusPublished),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text(l10n.statusArchived),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _status = val;
                            _fetchData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _departmentId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              l10n.allDepts,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'company-wide',
                            child: Text(
                              l10n.companyWide,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ..._departments.map(
                            (d) => DropdownMenuItem(
                              value: d.id.toString(),
                              child: Text(
                                d.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _departmentId = val;
                            _fetchData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Title', 'title'),
                      const SizedBox(width: 8),
                      _buildSortChip('Effective Date', 'effective_date'),
                      const SizedBox(width: 8),
                      _buildSortChip('Review Date', 'review_date'),
                      const SizedBox(width: 8),
                      _buildSortChip('Created', 'created_at'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? LoadingIndicator(message: l10n.loadingPolicies)
                : _policies.isEmpty
                ? Center(
                    child: Text(
                      l10n.noPoliciesFound,
                      style: const TextStyle(color: AppColors.grey500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _policies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = _policies[i];
                      final statusColor = p.status == 'published'
                          ? AppColors.success
                          : p.status == 'draft'
                          ? AppColors.warning
                          : AppColors.grey500;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.infoLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.policy,
                                    color: AppColors.info,
                                    size: 22,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (p.creatorName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'By ${p.creatorName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey400,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    p.department?.name ?? l10n.companyWide,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    'v${p.version}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                if (p.effectiveDate != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.policyEffectivePrefix(
                                        p.effectiveDate!,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (p.status == 'published' && p.stats != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          l10n.policyAcknowledged(
                                            p.stats!.acknowledged,
                                            p.stats!.target,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.grey800,
                                          ),
                                        ),
                                        Text(
                                          '${p.stats!.percentage}%',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: p.stats!.percentage / 100.0,
                                        backgroundColor: const Color(
                                          0xFFE2E8F0,
                                        ),
                                        color: AppColors.success,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showDetail(p),
                                  icon: const Icon(
                                    Icons.visibility,
                                    size: 16,
                                    color: AppColors.info,
                                  ),
                                  label: Text(
                                    l10n.viewBtn,
                                    style: const TextStyle(
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                                if (p.status != 'published')
                                  TextButton.icon(
                                    onPressed: () =>
                                        _changeStatus(p.id, 'publish'),
                                    icon: const Icon(
                                      Icons.publish,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    label: Text(
                                      l10n.publishBtn,
                                      style: const TextStyle(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                if (p.status == 'published')
                                  TextButton.icon(
                                    onPressed: () =>
                                        _changeStatus(p.id, 'archive'),
                                    icon: const Icon(
                                      Icons.archive,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                    label: Text(
                                      l10n.archiveBtn,
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () => _showForm(p),
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.grey600,
                                  ),
                                  label: Text(
                                    l10n.editBtn,
                                    style: const TextStyle(
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _confirmDelete(p.id, p.title),
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: AppColors.danger,
                                  ),
                                  label: Text(
                                    l10n.deleteBtn,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing $_from-$_to of $_total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.grey600,
                        ),
                        onPressed: _currentPage > 1
                            ? () => _changePage(_currentPage - 1)
                            : null,
                      ),
                      Text(
                        '$_currentPage / $_lastPage',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.grey600,
                        ),
                        onPressed: _currentPage < _lastPage
                            ? () => _changePage(_currentPage + 1)
                            : null,
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

  Widget _buildSortChip(String label, String column) {
    final isActive = _sort == column;
    return GestureDetector(
      onTap: () => _toggleSort(column),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withAlpha(20)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.grey500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                _order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
