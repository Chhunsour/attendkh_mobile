import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart'
    show DepartmentData;
import 'package:mpg_hr_mobile_app/services/directory_repository.dart'
    show DirectoryRepository, EmployeeData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.performanceTrainingTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
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
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: l10n.tabReviews),
                Tab(text: l10n.tabTraining),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_ReviewsTab(), _TrainingTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── REVIEWS TAB ─────────────────────────────────────────────────────────────
class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  bool _loading = true;
  List<PerformanceReviewData> _reviews = [];
  List<String> _periods = [];
  List<EmployeeData> _employees = [];

  String _search = '';
  String _period = 'all';
  String _type = 'all';
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _from = 0;
  int _to = 0;
  final PerformanceRepository _repo = PerformanceRepository();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getReviews(
        search: _search,
        period: _period,
        type: _type,
        page: _currentPage,
      );
      setState(() {
        _reviews = res.reviews;
        _periods = res.periods;
        _employees = res.employees;
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

  _ChipStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const _ChipStyle(
          AppColors.grey100,
          AppColors.grey700,
          AppColors.grey300,
        );
      case 'submitted':
        return const _ChipStyle(
          AppColors.warningLight,
          AppColors.warning,
          AppColors.warningLight,
        );
      case 'acknowledged':
        return const _ChipStyle(
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryLight,
        );
      case 'completed':
        return const _ChipStyle(
          AppColors.successLight,
          AppColors.success,
          AppColors.successLight,
        );
      default:
        return const _ChipStyle(
          AppColors.grey100,
          AppColors.grey700,
          AppColors.grey300,
        );
    }
  }

  _ChipStyle _typeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'self':
        return const _ChipStyle(
          Color(0xFFF3E8FF),
          Color(0xFF7E22CE),
          Color(0xFFF3E8FF),
        );
      case 'manager':
        return const _ChipStyle(
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryLight,
        );
      case 'peer':
        return const _ChipStyle(
          AppColors.successLight,
          AppColors.success,
          AppColors.successLight,
        );
      case '360':
        return const _ChipStyle(
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryLight,
        );
      default:
        return const _ChipStyle(
          AppColors.grey100,
          AppColors.grey700,
          AppColors.grey300,
        );
    }
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt != null) return DateFormat('dd MMM yyyy').format(dt);
    return d.split(' ')[0];
  }

  Widget _buildPagination() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $_from to $_to of $_total reviews',
            style: const TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _changePage(_currentPage - 1)
                    : null,
                color: AppColors.primary,
              ),
              Text(
                '$_currentPage / $_lastPage',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _lastPage
                    ? () => _changePage(_currentPage + 1)
                    : null,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeReview(PerformanceReviewData r) async {
    try {
      await _repo.acknowledgeReview(r.id);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteReview(PerformanceReviewData r) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteReviewTitle),
        content: Text(l10n.deleteReviewConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.deleteReview(r.id);
        _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  void _showView(PerformanceReviewData r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildViewInfoTile(
                      'Employee',
                      '${r.employee?.fullName ?? ''} ${r.employee?.khmerName ?? ''}'
                          .trim(),
                    ),
                    _buildViewInfoTile(
                      'Reviewer',
                      '${r.reviewer?.fullName ?? ''} ${r.reviewer?.khmerName ?? ''}'
                          .trim(),
                    ),
                    _buildViewInfoTile('Period', r.reviewPeriod ?? 'N/A'),
                    _buildViewInfoTile(
                      'Dates',
                      r.periodStart != null && r.periodEnd != null
                          ? '${_formatDate(r.periodStart!)} - ${_formatDate(r.periodEnd!)}'
                          : 'N/A',
                    ),
                    _buildViewInfoTile(
                      'Review Date',
                      r.reviewDate != null ? _formatDate(r.reviewDate!) : 'N/A',
                    ),
                    _buildViewInfoTile('Type', r.reviewType.toUpperCase()),
                    _buildViewInfoTile('Status', r.status.toUpperCase()),
                    _buildViewInfoTile(
                      'Overall Rating',
                      r.overallRating != null
                          ? '${r.overallRating} / 5'
                          : 'Not rated',
                    ),
                    const SizedBox(height: 16),
                    _buildViewSection('Strengths', r.strengths),
                    _buildViewSection(
                      'Areas for Improvement',
                      r.areasForImprovement,
                    ),
                    _buildViewSection('Goals for Next Period', r.goals),
                    _buildViewSection('Comments', r.comments),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSection(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content?.isNotEmpty == true
                  ? content!
                  : 'No information provided.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm([PerformanceReviewData? item]) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = item != null;
    int selectedRating = isEdit ? (item.overallRating ?? 0) : 0;
    String selectedEmpId = isEdit ? (item.employee?.id.toString() ?? '') : '';
    String selectedType = isEdit ? item.reviewType : 'manager';
    final periodCtrl = TextEditingController(
      text: isEdit ? (item.reviewPeriod ?? '') : '',
    );
    final strengthsCtrl = TextEditingController(
      text: isEdit ? (item.strengths ?? '') : '',
    );
    final improvementsCtrl = TextEditingController(
      text: isEdit ? (item.areasForImprovement ?? '') : '',
    );
    final goalsCtrl = TextEditingController(
      text: isEdit ? (item.goals ?? '') : '',
    );
    final commentsCtrl = TextEditingController(
      text: isEdit ? (item.comments ?? '') : '',
    );

    // Default dates for new reviews
    final pStartCtrl = TextEditingController(
      text: isEdit ? (item.periodStart ?? '') : '',
    );
    final pEndCtrl = TextEditingController(
      text: isEdit ? (item.periodEnd ?? '') : '',
    );
    final revDateCtrl = TextEditingController(
      text: isEdit
          ? (item.reviewDate ?? '')
          : DateTime.now().toString().substring(0, 10),
    );

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
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? l10n.editReviewTitle : l10n.createReviewTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedEmpId.isEmpty
                          ? null
                          : selectedEmpId,
                      decoration: InputDecoration(
                        labelText: l10n.employeeRequired,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id.toString(),
                              child: Text(
                                '${e.fullName} ${e.khmerName ?? ''}'.trim(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEdit
                          ? null
                          : (val) =>
                                setSheetState(() => selectedEmpId = val ?? ''),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: l10n.reviewTypeRequired,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text(l10n.reviewTypeManager),
                        ),
                        DropdownMenuItem(
                          value: 'self',
                          child: Text(l10n.reviewTypeSelf),
                        ),
                        DropdownMenuItem(
                          value: 'peer',
                          child: Text(l10n.reviewTypePeer),
                        ),
                        DropdownMenuItem(
                          value: '360',
                          child: Text(l10n.reviewType360),
                        ),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => selectedType = val ?? 'manager'),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: periodCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.periodRequired,
                        hintText: l10n.periodHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = pStartCtrl.text.isNotEmpty
                                  ? (DateTime.tryParse(pStartCtrl.text) ??
                                        DateTime.now())
                                  : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(
                                  () => pStartCtrl.text = picked
                                      .toIso8601String()
                                      .substring(0, 10),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.periodStartRequired,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pStartCtrl.text.isNotEmpty
                                            ? DateFormat('dd MMM yyyy').format(
                                                DateTime.parse(pStartCtrl.text),
                                              )
                                            : 'Select date...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: pStartCtrl.text.isNotEmpty
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: pStartCtrl.text.isNotEmpty
                                              ? AppColors.grey900
                                              : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = pEndCtrl.text.isNotEmpty
                                  ? (DateTime.tryParse(pEndCtrl.text) ??
                                        DateTime.now())
                                  : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(
                                  () => pEndCtrl.text = picked
                                      .toIso8601String()
                                      .substring(0, 10),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.periodEndRequired,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pEndCtrl.text.isNotEmpty
                                            ? DateFormat('dd MMM yyyy').format(
                                                DateTime.parse(pEndCtrl.text),
                                              )
                                            : 'Select date...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: pEndCtrl.text.isNotEmpty
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: pEndCtrl.text.isNotEmpty
                                              ? AppColors.grey900
                                              : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 18,
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
                        final init = revDateCtrl.text.isNotEmpty
                            ? (DateTime.tryParse(revDateCtrl.text) ??
                                  DateTime.now())
                            : DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: init,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: AppColors.grey900,
                              ),
                              dialogTheme: DialogThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(
                            () => revDateCtrl.text = picked
                                .toIso8601String()
                                .substring(0, 10),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                                Text(
                                  l10n.reviewDateRequired,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  revDateCtrl.text.isNotEmpty
                                      ? DateFormat('dd MMM yyyy').format(
                                          DateTime.parse(revDateCtrl.text),
                                        )
                                      : 'Select date...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: revDateCtrl.text.isNotEmpty
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: revDateCtrl.text.isNotEmpty
                                        ? AppColors.grey900
                                        : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StarRatingPicker(
                      rating: selectedRating,
                      onChanged: (val) =>
                          setSheetState(() => selectedRating = val),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: strengthsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.strengthsOptional,
                        hintText: 'Key accomplishments...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: improvementsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.areasForImprovementOptional,
                        hintText: 'Areas to develop or improve...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: goalsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.goalsOptional,
                        hintText: 'Target goals for next period...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.commentsOptional,
                        hintText: 'Final reviewer comments...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedEmpId.isEmpty ||
                              periodCtrl.text.trim().isEmpty ||
                              (pStartCtrl.text.isEmpty && !isEdit) ||
                              (pEndCtrl.text.isEmpty && !isEdit)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.fieldRequired),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          try {
                            final data = {
                              if (!isEdit)
                                'employee_id': int.parse(selectedEmpId),
                              'review_type': selectedType,
                              'review_period': periodCtrl.text.trim(),
                              if (pStartCtrl.text.isNotEmpty)
                                'period_start': pStartCtrl.text.trim(),
                              if (pEndCtrl.text.isNotEmpty)
                                'period_end': pEndCtrl.text.trim(),
                              'review_date': revDateCtrl.text.trim(),
                              if (selectedRating > 0)
                                'overall_rating': selectedRating,
                              if (strengthsCtrl.text.isNotEmpty)
                                'strengths': strengthsCtrl.text.trim(),
                              if (improvementsCtrl.text.isNotEmpty)
                                'areas_for_improvement': improvementsCtrl.text
                                    .trim(),
                              if (goalsCtrl.text.isNotEmpty)
                                'goals': goalsCtrl.text.trim(),
                              if (commentsCtrl.text.isNotEmpty)
                                'comments': commentsCtrl.text.trim(),
                            };
                            if (isEdit) {
                              await _repo.updateReview(item.id, data);
                            } else {
                              await _repo.createReview(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
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
                          isEdit ? l10n.saveChangesBtn : l10n.createReviewTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceLight,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchEmployeesHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
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
                        initialValue: _type,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(l10n.allTypes),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text(l10n.reviewTypeManager),
                          ),
                          DropdownMenuItem(
                            value: 'self',
                            child: Text(l10n.reviewTypeSelf),
                          ),
                          DropdownMenuItem(
                            value: 'peer',
                            child: Text(l10n.reviewTypePeer),
                          ),
                          DropdownMenuItem(
                            value: '360',
                            child: Text(l10n.reviewType360),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _type = val;
                            _fetchData();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _period,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(l10n.allPeriods),
                          ),
                          ..._periods.map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _period = val;
                            _fetchData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? LoadingIndicator(message: l10n.loadingReviews)
                : _reviews.isEmpty
                ? Center(
                    child: Text(
                      l10n.noReviews,
                      style: const TextStyle(color: AppColors.grey500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length + (_lastPage > 1 ? 1 : 0),
                    separatorBuilder: (_, i) => i == _reviews.length - 1
                        ? const SizedBox.shrink()
                        : const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == _reviews.length) return _buildPagination();
                      final r = _reviews[i];
                      final s = _statusStyle(r.status);
                      final t = _typeStyle(r.reviewType);
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: s.bg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.assessment,
                                        color: s.text,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r.employee?.fullName ?? ''} ${r.employee?.khmerName ?? ''}'
                                              .trim(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: t.bg,
                                            border: Border.all(color: t.border),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            r.reviewType.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: t.text,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.bg,
                                    border: Border.all(color: s.border),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: s.text,
                                    ),
                                  ),
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
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    border: Border.all(
                                      color: AppColors.grey300,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${l10n.periodRequired.replaceAll(' *', '')}: ${r.reviewPeriod ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                ),
                                if (r.periodStart != null &&
                                    r.periodEnd != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.grey100,
                                      border: Border.all(
                                        color: AppColors.grey300,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_formatDate(r.periodStart!)} - ${_formatDate(r.periodEnd!)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.grey700,
                                      ),
                                    ),
                                  ),
                                if (r.overallRating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningLight,
                                      border: Border.all(
                                        color: AppColors.warningLight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${r.overallRating} / 5',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _showView(r),
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: AppColors.grey600,
                                  ),
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  onPressed: () => _showForm(r),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Edit',
                                ),
                                if (r.status == 'draft')
                                  IconButton(
                                    onPressed: () async {
                                      await _repo.submitReview(r.id);
                                      _fetchData();
                                    },
                                    icon: const Icon(
                                      Icons.check,
                                      color: AppColors.success,
                                    ),
                                    tooltip: 'Submit',
                                  ),
                                if (r.status == 'submitted')
                                  IconButton(
                                    onPressed: () => _acknowledgeReview(r),
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Acknowledge',
                                  ),
                                IconButton(
                                  onPressed: () => _deleteReview(r),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── STAR RATING PICKER COMPONENT ──────────────────────────────────────────

class _StarRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRatingPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.overallRatingPrefix.replaceAll(': ', ''),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
              Text(
                rating > 0 ? '$rating / 5' : l10n.notRated,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rating > 0 ? AppColors.warning : AppColors.grey400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= rating;
              return GestureDetector(
                onTap: () => onChanged(starValue == rating ? 0 : starValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFilled ? AppColors.warning : AppColors.grey400,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ChipStyle {
  final Color bg;
  final Color text;
  final Color border;
  const _ChipStyle(this.bg, this.text, this.border);
}

class _TrainingTab extends StatefulWidget {
  const _TrainingTab();
  @override
  State<_TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<_TrainingTab> {
  bool _loading = true;
  List<TrainingCourseData> _trainings = [];
  List<DepartmentData> _departments = [];
  List<EmployeeData> _employees = [];

  String _search = '';
  String _departmentId = 'all';
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  int _from = 0;
  int _to = 0;
  final PerformanceRepository _repo = PerformanceRepository();

  _ChipStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return const _ChipStyle(
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryLight,
        );
      case 'ongoing':
        return const _ChipStyle(
          AppColors.warningLight,
          AppColors.warning,
          AppColors.warningLight,
        );
      case 'completed':
        return const _ChipStyle(
          AppColors.successLight,
          AppColors.success,
          AppColors.successLight,
        );
      case 'cancelled':
        return const _ChipStyle(
          AppColors.dangerLight,
          AppColors.danger,
          AppColors.dangerLight,
        );
      case 'draft':
      default:
        return const _ChipStyle(
          AppColors.grey100,
          AppColors.grey700,
          AppColors.grey300,
        );
    }
  }

  _ChipStyle _levelStyle(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return const _ChipStyle(
          AppColors.successLight,
          AppColors.success,
          AppColors.successLight,
        );
      case 'intermediate':
        return const _ChipStyle(
          AppColors.warningLight,
          AppColors.warning,
          AppColors.warningLight,
        );
      case 'advanced':
        return const _ChipStyle(
          AppColors.dangerLight,
          AppColors.danger,
          AppColors.dangerLight,
        );
      default:
        return const _ChipStyle(
          AppColors.grey100,
          AppColors.grey700,
          AppColors.grey300,
        );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey400),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt != null) return DateFormat('dd MMM yyyy').format(dt);
    return d.split(' ')[0];
  }

  Widget _buildPagination() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $_from to $_to of $_total trainings',
            style: const TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () => _changePage(_currentPage - 1)
                    : null,
                color: AppColors.primary,
              ),
              Text(
                '$_currentPage / $_lastPage',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _lastPage
                    ? () => _changePage(_currentPage + 1)
                    : null,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getTrainings(
        search: _search,
        departmentId: _departmentId,
        page: _currentPage,
      );
      final empsList = await DirectoryRepository().getEmployees();
      setState(() {
        _trainings = res.trainings;
        _departments = res.departments;
        _employees = empsList;
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

  Future<void> _deleteTraining(TrainingCourseData t) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTrainingTitle),
        content: Text(l10n.deleteTrainingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.deleteTraining(t.id);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.trainingDeletedSuccess),
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
    }
  }

  void _showForm([TrainingCourseData? item]) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final descCtrl = TextEditingController(
      text: isEdit ? (item.description ?? '') : '',
    );
    final contentCtrl = TextEditingController(
      text: isEdit ? (item.content ?? '') : '',
    );
    final durationCtrl = TextEditingController(
      text: isEdit ? (item.durationHours?.toString() ?? '') : '',
    );
    final instructorCtrl = TextEditingController(
      text: isEdit ? (item.instructor ?? '') : '',
    );
    final locationCtrl = TextEditingController(
      text: isEdit ? (item.location ?? '') : '',
    );
    final maxParticipantsCtrl = TextEditingController(
      text: isEdit ? (item.maxParticipants?.toString() ?? '') : '',
    );
    final startDateCtrl = TextEditingController(
      text: isEdit ? (item.startDate ?? '') : '',
    );
    final endDateCtrl = TextEditingController(
      text: isEdit ? (item.endDate ?? '') : '',
    );
    final notesCtrl = TextEditingController(
      text: isEdit ? (item.notes ?? '') : '',
    );

    String selectedDeptId = isEdit ? (item.departmentId?.toString() ?? '') : '';
    String selectedLevel = isEdit ? (item.level ?? 'beginner') : 'beginner';
    String selectedStatus = isEdit ? item.status : 'draft';
    File? coverImageFile;

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
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? l10n.editTrainingTitle
                          : l10n.createTrainingTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            final compressed =
                                await ImageCompressor.compressToWebp(
                                  picked.path,
                                );
                            setSheetState(() => coverImageFile = compressed);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            color: AppColors.grey100,
                            child: coverImageFile != null
                                ? Image.file(coverImageFile!, fit: BoxFit.cover)
                                : (item?.coverImage != null &&
                                      item!.coverImage!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: item.coverImage!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 600,
                                    memCacheHeight: 400,
                                    placeholder: (ctx, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                    errorWidget: (ctx, url, err) => Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.image,
                                          size: 48,
                                          color: AppColors.grey400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          l10n.replaceCoverImage,
                                          style: const TextStyle(
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image,
                                        size: 48,
                                        color: AppColors.grey400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.uploadCoverImage,
                                        style: const TextStyle(
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.titleFieldLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
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
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selectedLevel,
                            decoration: InputDecoration(
                              labelText: l10n.levelLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'beginner',
                                child: Text(l10n.levelBeginner),
                              ),
                              DropdownMenuItem(
                                value: 'intermediate',
                                child: Text(l10n.levelIntermediate),
                              ),
                              DropdownMenuItem(
                                value: 'advanced',
                                child: Text(l10n.levelAdvanced),
                              ),
                            ],
                            onChanged: (val) => setSheetState(
                              () => selectedLevel = val ?? 'beginner',
                            ),
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
                                value: 'ongoing',
                                child: Text(l10n.statusOngoing),
                              ),
                              DropdownMenuItem(
                                value: 'completed',
                                child: Text(l10n.statusCompleted),
                              ),
                              DropdownMenuItem(
                                value: 'cancelled',
                                child: Text(l10n.statusCancelled),
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
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.durationHours,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxParticipantsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.maxCapacity,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                            controller: instructorCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.instructorName,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.locationLink,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = startDateCtrl.text.isNotEmpty
                                  ? (DateTime.tryParse(startDateCtrl.text) ??
                                        DateTime.now())
                                  : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(
                                  () => startDateCtrl.text = picked
                                      .toIso8601String()
                                      .substring(0, 10),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.startDateLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        startDateCtrl.text.isNotEmpty
                                            ? DateFormat('dd MMM yyyy').format(
                                                DateTime.parse(
                                                  startDateCtrl.text,
                                                ),
                                              )
                                            : l10n.selectDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              startDateCtrl.text.isNotEmpty
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: startDateCtrl.text.isNotEmpty
                                              ? AppColors.grey900
                                              : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = endDateCtrl.text.isNotEmpty
                                  ? (DateTime.tryParse(endDateCtrl.text) ??
                                        DateTime.now())
                                  : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(
                                  () => endDateCtrl.text = picked
                                      .toIso8601String()
                                      .substring(0, 10),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.endDateLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        endDateCtrl.text.isNotEmpty
                                            ? DateFormat('dd MMM yyyy').format(
                                                DateTime.parse(
                                                  endDateCtrl.text,
                                                ),
                                              )
                                            : l10n.selectDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              endDateCtrl.text.isNotEmpty
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: endDateCtrl.text.isNotEmpty
                                              ? AppColors.grey900
                                              : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.trainingDescription,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.trainingContent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.trainingNotes,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.titleRequired),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          try {
                            final data = {
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'content': contentCtrl.text.trim(),
                              if (selectedDeptId.isNotEmpty)
                                'department_id': selectedDeptId,
                              'level': selectedLevel,
                              'status': selectedStatus,
                              if (durationCtrl.text.isNotEmpty)
                                'duration_hours': int.tryParse(
                                  durationCtrl.text.trim(),
                                ),
                              if (maxParticipantsCtrl.text.isNotEmpty)
                                'max_participants': int.tryParse(
                                  maxParticipantsCtrl.text.trim(),
                                ),
                              if (instructorCtrl.text.isNotEmpty)
                                'instructor': instructorCtrl.text.trim(),
                              if (locationCtrl.text.isNotEmpty)
                                'location': locationCtrl.text.trim(),
                              if (startDateCtrl.text.isNotEmpty)
                                'start_date': startDateCtrl.text.trim(),
                              if (endDateCtrl.text.isNotEmpty)
                                'end_date': endDateCtrl.text.trim(),
                              if (notesCtrl.text.isNotEmpty)
                                'notes': notesCtrl.text.trim(),
                            };
                            if (isEdit) {
                              await _repo.updateTraining(
                                item.id,
                                data,
                                coverImagePath: coverImageFile?.path,
                              );
                            } else {
                              await _repo.createTraining(
                                data,
                                coverImagePath: coverImageFile?.path,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
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
                          isEdit
                              ? l10n.saveChangesBtn
                              : l10n.createTrainingTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceLight,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchTrainingsHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
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
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _departmentId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(l10n.allDepartments),
                    ),
                    DropdownMenuItem(
                      value: 'company-wide',
                      child: Text(l10n.companyWide),
                    ),
                    ..._departments.map(
                      (d) => DropdownMenuItem(
                        value: d.id.toString(),
                        child: Text(d.name),
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
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? LoadingIndicator(message: l10n.loadingTrainings)
                : _trainings.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTrainings,
                      style: const TextStyle(color: AppColors.grey500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trainings.length + (_lastPage > 1 ? 1 : 0),
                    separatorBuilder: (_, i) => i == _trainings.length - 1
                        ? const SizedBox.shrink()
                        : const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == _trainings.length) return _buildPagination();
                      final t = _trainings[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                margin: const EdgeInsets.only(bottom: 12),
                                color: AppColors.grey100,
                                child:
                                    t.coverImage != null &&
                                        t.coverImage!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: t.coverImage!.startsWith('http')
                                            ? t.coverImage!
                                            : '${DioClient.storageUrl}/${t.coverImage!.startsWith('/') ? t.coverImage!.substring(1) : t.coverImage!}',
                                        fit: BoxFit.cover,
                                        memCacheWidth: 600,
                                        memCacheHeight: 300,
                                        placeholder: (ctx, url) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                        errorWidget: (ctx, url, err) =>
                                            const Center(
                                              child: Icon(
                                                Icons.menu_book,
                                                size: 48,
                                                color: AppColors.grey300,
                                              ),
                                            ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.menu_book,
                                          size: 48,
                                          color: AppColors.grey300,
                                        ),
                                      ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final s = _statusStyle(t.status);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: s.bg,
                                        border: Border.all(color: s.border),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        t.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: s.text,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.description ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    border: Border.all(
                                      color: AppColors.primaryLight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t.department?.name ?? l10n.companyWide,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final l = _levelStyle(t.level);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: l.bg,
                                        border: Border.all(color: l.border),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (t.level ?? 'BEGINNER').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: l.text,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (t.instructor != null &&
                                t.instructor!.isNotEmpty)
                              _buildInfoRow(Icons.people, t.instructor!),
                            if (t.startDate != null && t.endDate != null)
                              _buildInfoRow(
                                Icons.calendar_today,
                                '${_formatDate(t.startDate!)} - ${_formatDate(t.endDate!)}',
                              ),
                            if (t.durationHours != null)
                              _buildInfoRow(
                                Icons.access_time,
                                '${t.durationHours}h',
                              ),
                            if (t.location != null && t.location!.isNotEmpty)
                              _buildInfoRow(Icons.location_on, t.location!),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _showEnrollmentSheet(t),
                                  icon: const Icon(
                                    Icons.people_outline,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Enrollments',
                                ),
                                IconButton(
                                  onPressed: () => _showForm(t),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.grey600,
                                  ),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  onPressed: () => _deleteTraining(t),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEnrollmentSheet(TrainingCourseData t) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? selectedEmpIdToEnroll;
        bool loadingEnrollments = true;
        List<Map<String, dynamic>> enrollments = [];

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void fetchEnrollments() async {
              try {
                final list = await _repo.getTrainingEnrollments(t.id);
                setSheetState(() {
                  enrollments = list;
                  loadingEnrollments = false;
                });
              } catch (e) {
                setSheetState(() => loadingEnrollments = false);
              }
            }

            if (loadingEnrollments) {
              fetchEnrollments();
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
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
                          '${l10n.enrollmentsTitle}: ${t.title}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Enroll Employee Selector Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedEmpIdToEnroll,
                          decoration: InputDecoration(
                            hintText: l10n.selectEmployeeToEnroll,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _employees
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id.toString(),
                                  child: Text('${e.fullName} ${e.khmerName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedEmpIdToEnroll = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onPressed: selectedEmpIdToEnroll == null
                            ? null
                            : () async {
                                try {
                                  await _repo.enrollEmployee(
                                    t.id,
                                    int.parse(selectedEmpIdToEnroll!),
                                  );
                                  setSheetState(() {
                                    selectedEmpIdToEnroll = null;
                                    loadingEnrollments = true;
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.employeeEnrolledSuccess,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          l10n.enrollBtn,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${l10n.enrolledParticipantsTitle} (${enrollments.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: loadingEnrollments
                        ? const Center(child: CircularProgressIndicator())
                        : enrollments.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noEmployeesEnrolled,
                              style: const TextStyle(color: AppColors.grey500),
                            ),
                          )
                        : ListView.separated(
                            itemCount: enrollments.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, index) {
                              final en = enrollments[index];
                              final emp = en['employee'] ?? {};
                              final empName =
                                  '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'
                                      .trim();
                              final status = (en['status'] ?? 'enrolled')
                                  .toString()
                                  .toUpperCase();
                              final progress = en['progress_percentage'] ?? 0;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withAlpha(26),
                                      child: Text(
                                        empName.isNotEmpty ? empName[0] : 'E',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            empName.isEmpty
                                                ? 'Employee'
                                                : empName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${l10n.progressLabel}: $progress% | ${l10n.statusLabel}: $status',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
