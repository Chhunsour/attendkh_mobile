import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart' show DepartmentData;
import 'package:mpg_hr_mobile_app/services/directory_repository.dart' show DirectoryRepository, EmployeeData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.performanceTrainingTitle, style: const TextStyle(color: AppColors.grey800, fontSize: 18, fontWeight: FontWeight.w700)),
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
              tabs: [Tab(text: l10n.tabReviews), Tab(text: l10n.tabTraining)],
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
  final PerformanceRepository _repo = PerformanceRepository();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getReviews(search: _search, period: _period, type: _type);
      setState(() {
        _reviews = res.reviews;
        _periods = res.periods;
        _employees = res.employees;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showForm([PerformanceReviewData? item]) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = item != null;
    int selectedRating = isEdit ? (item.overallRating ?? 0) : 0;
    String selectedEmpId = isEdit ? (item.employee?.id.toString() ?? '') : '';
    String selectedType = isEdit ? item.reviewType : 'manager';
    final periodCtrl = TextEditingController(text: isEdit ? (item.reviewPeriod ?? '') : '');
    final strengthsCtrl = TextEditingController(text: isEdit ? (item.strengths ?? '') : '');
    final improvementsCtrl = TextEditingController(text: isEdit ? (item.areasForImprovement ?? '') : '');
    final goalsCtrl = TextEditingController(text: isEdit ? (item.goals ?? '') : '');
    final commentsCtrl = TextEditingController(text: isEdit ? (item.comments ?? '') : '');
    String selectedStatus = isEdit ? item.status : 'draft';
    
    // Default dates for new reviews
    final pStartCtrl = TextEditingController(text: isEdit ? (item.periodStart ?? '') : '');
    final pEndCtrl = TextEditingController(text: isEdit ? (item.periodEnd ?? '') : '');
    final revDateCtrl = TextEditingController(text: isEdit ? (item.reviewDate ?? '') : DateTime.now().toString().substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? l10n.editReviewTitle : l10n.createReviewTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedEmpId.isEmpty ? null : selectedEmpId,
                      decoration: InputDecoration(labelText: l10n.employeeRequired, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.firstName} ${e.lastName}'))).toList(),
                      onChanged: isEdit ? null : (val) => setSheetState(() => selectedEmpId = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: InputDecoration(labelText: l10n.reviewTypeRequired, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        DropdownMenuItem(value: 'manager', child: Text(l10n.reviewTypeManager)),
                        DropdownMenuItem(value: 'self', child: Text(l10n.reviewTypeSelf)),
                        DropdownMenuItem(value: 'peer', child: Text(l10n.reviewTypePeer)),
                        DropdownMenuItem(value: '360', child: Text(l10n.reviewType360)),
                      ],
                      onChanged: (val) => setSheetState(() => selectedType = val ?? 'manager'),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(controller: periodCtrl, decoration: InputDecoration(labelText: l10n.periodRequired, hintText: l10n.periodHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = pStartCtrl.text.isNotEmpty ? (DateTime.tryParse(pStartCtrl.text) ?? DateTime.now()) : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => pStartCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.periodStartRequired, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        pStartCtrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(pStartCtrl.text)) : 'Select date...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: pStartCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                          color: pStartCtrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = pEndCtrl.text.isNotEmpty ? (DateTime.tryParse(pEndCtrl.text) ?? DateTime.now()) : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => pEndCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.periodEndRequired, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        pEndCtrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(pEndCtrl.text)) : 'Select date...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: pEndCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                          color: pEndCtrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
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
                        final init = revDateCtrl.text.isNotEmpty ? (DateTime.tryParse(revDateCtrl.text) ?? DateTime.now()) : DateTime.now();
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() => revDateCtrl.text = picked.toIso8601String().substring(0, 10));
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.reviewDateRequired, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                const SizedBox(height: 4),
                                Text(
                                  revDateCtrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(revDateCtrl.text)) : 'Select date...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: revDateCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                    color: revDateCtrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StarRatingPicker(
                      rating: selectedRating,
                      onChanged: (val) => setSheetState(() => selectedRating = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedStatus,
                      decoration: InputDecoration(labelText: l10n.statusLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        DropdownMenuItem(value: 'draft', child: Text(l10n.statusDraft)),
                        DropdownMenuItem(value: 'submitted', child: Text(l10n.statusSubmitted)),
                        DropdownMenuItem(value: 'acknowledged', child: Text(l10n.statusAcknowledged)),
                        DropdownMenuItem(value: 'completed', child: Text(l10n.statusCompleted)),
                      ],
                      onChanged: (val) => setSheetState(() => selectedStatus = val ?? 'draft'),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: strengthsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.strengthsOptional, hintText: 'Key accomplishments...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: improvementsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.areasForImprovementOptional, hintText: 'Areas to develop or improve...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: goalsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.goalsOptional, hintText: 'Target goals for next period...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.commentsOptional, hintText: 'Final reviewer comments...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (selectedEmpId.isEmpty || periodCtrl.text.trim().isEmpty || (pStartCtrl.text.isEmpty && !isEdit) || (pEndCtrl.text.isEmpty && !isEdit)) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fieldRequired), backgroundColor: AppColors.danger)); 
                            return;
                          }
                          try {
                            final data = {
                              if (!isEdit) 'employee_id': int.parse(selectedEmpId),
                              'review_type': selectedType,
                              'review_period': periodCtrl.text.trim(),
                              if (pStartCtrl.text.isNotEmpty) 'period_start': pStartCtrl.text.trim(),
                              if (pEndCtrl.text.isNotEmpty) 'period_end': pEndCtrl.text.trim(),
                              'review_date': revDateCtrl.text.trim(),
                              if (selectedRating > 0) 'overall_rating': selectedRating,
                              if (strengthsCtrl.text.isNotEmpty) 'strengths': strengthsCtrl.text.trim(),
                              if (improvementsCtrl.text.isNotEmpty) 'areas_for_improvement': improvementsCtrl.text.trim(),
                              if (goalsCtrl.text.isNotEmpty) 'goals': goalsCtrl.text.trim(),
                              if (commentsCtrl.text.isNotEmpty) 'comments': commentsCtrl.text.trim(),
                              'status': selectedStatus,
                            };
                            if (isEdit) {
                              await _repo.updateReview(item.id, data);
                            } else {
                              await _repo.createReview(data);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }
                        },
                        child: Text(isEdit ? l10n.saveChangesBtn : l10n.createReviewTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
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
          padding: const EdgeInsets.all(16), color: AppColors.surfaceLight,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(hintText: l10n.searchEmployeesHint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey300)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onSubmitted: (val) { _search = val; _fetchData(); },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: _type,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(l10n.allTypes)),
                        DropdownMenuItem(value: 'manager', child: Text(l10n.reviewTypeManager)),
                        DropdownMenuItem(value: 'self', child: Text(l10n.reviewTypeSelf)),
                        DropdownMenuItem(value: 'peer', child: Text(l10n.reviewTypePeer)),
                        DropdownMenuItem(value: '360', child: Text(l10n.reviewType360)),
                      ],
                      onChanged: (val) { if (val != null) { _type = val; _fetchData(); } },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: _period,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(l10n.allPeriods)),
                        ..._periods.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (val) { if (val != null) { _period = val; _fetchData(); } },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading ? LoadingIndicator(message: l10n.loadingReviews) : _reviews.isEmpty ? Center(child: Text(l10n.noReviews, style: const TextStyle(color: AppColors.grey500))) : ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: _reviews.length, separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = _reviews[i];
              final statusColor = r.status == 'completed' ? AppColors.success : r.status == 'submitted' ? AppColors.info : AppColors.warning;
              return Container(
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)), padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.assessment, color: statusColor, size: 22)),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${r.employee?.firstName ?? ''} ${r.employee?.lastName ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(r.reviewType.toUpperCase(), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            ])
                          ],
                        ),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withAlpha(26), borderRadius: BorderRadius.circular(6)), child: Text(r.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)), child: Text('${l10n.periodRequired.replaceAll(' *', '')}: ${r.reviewPeriod ?? 'N/A'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        if (r.overallRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text('${r.overallRating} / 5', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (r.status == 'draft') TextButton.icon(onPressed: () async { await _repo.submitReview(r.id); _fetchData(); }, icon: const Icon(Icons.send, size: 16), label: Text(l10n.submit)),
                        TextButton.icon(onPressed: () => _showForm(r), icon: const Icon(Icons.edit, size: 16), label: Text(l10n.editBtn)),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ));
  }
}

// ─── STAR RATING PICKER COMPONENT ──────────────────────────────────────────

class _StarRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRatingPicker({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.overallRatingPrefix.replaceAll(': ', ''),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  final PerformanceRepository _repo = PerformanceRepository();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getTrainings(search: _search, departmentId: _departmentId);
      final empsList = await DirectoryRepository().getEmployees();
      setState(() {
        _trainings = res.trainings;
        _departments = res.departments;
        _employees = empsList;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showForm([TrainingCourseData? item]) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    final contentCtrl = TextEditingController(text: isEdit ? (item.content ?? '') : '');
    final durationCtrl = TextEditingController(text: isEdit ? (item.durationHours?.toString() ?? '') : '');
    final instructorCtrl = TextEditingController(text: isEdit ? (item.instructor ?? '') : '');
    final locationCtrl = TextEditingController(text: isEdit ? (item.location ?? '') : '');
    final maxParticipantsCtrl = TextEditingController(text: isEdit ? (item.maxParticipants?.toString() ?? '') : '');
    final startDateCtrl = TextEditingController(text: isEdit ? (item.startDate ?? '') : '');
    final endDateCtrl = TextEditingController(text: isEdit ? (item.endDate ?? '') : '');
    final notesCtrl = TextEditingController(text: isEdit ? (item.notes ?? '') : '');

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
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? l10n.editTrainingTitle : l10n.createTrainingTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            final compressed = await ImageCompressor.compressToWebp(picked.path);
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
                                : (item?.coverImage != null && item!.coverImage!.isNotEmpty)
                                    ? Image.network(
                                        item.coverImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.image, size: 48, color: AppColors.grey400),
                                            const SizedBox(height: 8),
                                            Text(l10n.replaceCoverImage, style: const TextStyle(color: AppColors.grey500)),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.image, size: 48, color: AppColors.grey400),
                                          const SizedBox(height: 8),
                                          Text(l10n.uploadCoverImage, style: const TextStyle(color: AppColors.grey500)),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(controller: titleCtrl, decoration: InputDecoration(labelText: l10n.titleFieldLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: selectedDeptId.isEmpty ? null : selectedDeptId,
                      decoration: InputDecoration(labelText: l10n.departmentLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.companyWide)),
                        ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                      ],
                      onChanged: (val) => setSheetState(() => selectedDeptId = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true, initialValue: selectedLevel,
                            decoration: InputDecoration(labelText: l10n.levelLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: [
                              DropdownMenuItem(value: 'beginner', child: Text(l10n.levelBeginner)),
                              DropdownMenuItem(value: 'intermediate', child: Text(l10n.levelIntermediate)),
                              DropdownMenuItem(value: 'advanced', child: Text(l10n.levelAdvanced)),
                            ],
                            onChanged: (val) => setSheetState(() => selectedLevel = val ?? 'beginner'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true, initialValue: selectedStatus,
                            decoration: InputDecoration(labelText: l10n.statusLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: [
                              DropdownMenuItem(value: 'draft', child: Text(l10n.statusDraft)),
                              DropdownMenuItem(value: 'published', child: Text(l10n.statusPublished)),
                              DropdownMenuItem(value: 'ongoing', child: Text(l10n.statusOngoing)),
                              DropdownMenuItem(value: 'completed', child: Text(l10n.statusCompleted)),
                              DropdownMenuItem(value: 'cancelled', child: Text(l10n.statusCancelled)),
                            ],
                            onChanged: (val) => setSheetState(() => selectedStatus = val ?? 'draft'),
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
                            decoration: InputDecoration(labelText: l10n.durationHours, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxParticipantsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: l10n.maxCapacity, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                            decoration: InputDecoration(labelText: l10n.instructorName, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: locationCtrl,
                            decoration: InputDecoration(labelText: l10n.locationLink, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                              final init = startDateCtrl.text.isNotEmpty ? (DateTime.tryParse(startDateCtrl.text) ?? DateTime.now()) : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => startDateCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.startDateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        startDateCtrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(startDateCtrl.text)) : l10n.selectDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: startDateCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                          color: startDateCtrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = endDateCtrl.text.isNotEmpty ? (DateTime.tryParse(endDateCtrl.text) ?? DateTime.now()) : DateTime.now();
                              final picked = await showCustomDatePicker(
                                context,
                                initialDate: init,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => endDateCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.endDateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        endDateCtrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(endDateCtrl.text)) : l10n.selectDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: endDateCtrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                                          color: endDateCtrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.trainingDescription, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: contentCtrl, maxLines: 3, decoration: InputDecoration(labelText: l10n.trainingContent, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: notesCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.trainingNotes, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.titleRequired), backgroundColor: AppColors.danger)); 
                            return;
                          }
                          try {
                            final data = {
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              'content': contentCtrl.text.trim(),
                              if (selectedDeptId.isNotEmpty) 'department_id': selectedDeptId,
                              'level': selectedLevel,
                              'status': selectedStatus,
                              if (durationCtrl.text.isNotEmpty) 'duration_hours': int.tryParse(durationCtrl.text.trim()),
                              if (maxParticipantsCtrl.text.isNotEmpty) 'max_participants': int.tryParse(maxParticipantsCtrl.text.trim()),
                              if (instructorCtrl.text.isNotEmpty) 'instructor': instructorCtrl.text.trim(),
                              if (locationCtrl.text.isNotEmpty) 'location': locationCtrl.text.trim(),
                              if (startDateCtrl.text.isNotEmpty) 'start_date': startDateCtrl.text.trim(),
                              if (endDateCtrl.text.isNotEmpty) 'end_date': endDateCtrl.text.trim(),
                              if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                            };
                            if (isEdit) {
                              await _repo.updateTraining(item.id, data, coverImagePath: coverImageFile?.path);
                            } else {
                              await _repo.createTraining(data, coverImagePath: coverImageFile?.path);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchData();
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                          }
                        },
                        child: Text(isEdit ? l10n.saveChangesBtn : l10n.createTrainingTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
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
            padding: const EdgeInsets.all(16), color: AppColors.surfaceLight,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: l10n.searchTrainingsHint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey300)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onSubmitted: (val) { _search = val; _fetchData(); },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true, initialValue: _departmentId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(l10n.allPeriods.replaceAll('Periods', 'Departments'))), // Simple hack if allDepartments doesn't exist
                    DropdownMenuItem(value: 'company-wide', child: Text(l10n.companyWide)),
                    ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                  ],
                  onChanged: (val) { if (val != null) { _departmentId = val; _fetchData(); } },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading ? LoadingIndicator(message: l10n.loadingTrainings) : _trainings.isEmpty ? Center(child: Text(l10n.noTrainings, style: const TextStyle(color: AppColors.grey500))) : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: _trainings.length, separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = _trainings[i];
                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)), padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.coverImage != null && t.coverImage!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity, height: 140, margin: const EdgeInsets.only(bottom: 12),
                            color: const Color(0xFFF1F5F9),
                            child: Image.network(
                              t.coverImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.school_rounded, size: 40, color: AppColors.grey400),
                                    SizedBox(height: 4),
                                    Text('Image', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(6)), child: Text(t.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(t.description ?? '', style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)), child: Text(t.department?.name ?? l10n.companyWide, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)), child: Text(t.level?.toUpperCase() ?? 'BEGINNER', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEnrollmentSheet(t),
                            icon: const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
                            label: const Text('Enrollments', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _showForm(t),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text(l10n.deleteTrainingTitle),
                                      content: Text(l10n.deleteTrainingConfirm),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            try {
                                              await _repo.deleteTraining(t.id);
                                              _fetchData();
                                              if (ctx.mounted) {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                  SnackBar(content: Text(l10n.trainingDeletedSuccess), backgroundColor: AppColors.success),
                                                );
                                              }
                                            } catch (e) {
                                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                                            }
                                          },
                                          child: Text(l10n.deleteTitle, style: const TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      )
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
                left: 20, right: 20, top: 20,
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _employees.map((e) => DropdownMenuItem(
                            value: e.id.toString(),
                            child: Text('${e.firstName} ${e.lastName}'),
                          )).toList(),
                          onChanged: (val) => setSheetState(() => selectedEmpIdToEnroll = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: selectedEmpIdToEnroll == null ? null : () async {
                          try {
                            await _repo.enrollEmployee(t.id, int.parse(selectedEmpIdToEnroll!));
                            setSheetState(() {
                              selectedEmpIdToEnroll = null;
                              loadingEnrollments = true;
                            });
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(l10n.employeeEnrolledSuccess), backgroundColor: AppColors.success),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                        child: Text(l10n.enrollBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('${l10n.enrolledParticipantsTitle} (${enrollments.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey700)),
                  const SizedBox(height: 10),

                  Expanded(
                    child: loadingEnrollments
                        ? const Center(child: CircularProgressIndicator())
                        : enrollments.isEmpty
                            ? Center(child: Text(l10n.noEmployeesEnrolled, style: const TextStyle(color: AppColors.grey500)))
                            : ListView.separated(
                                itemCount: enrollments.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (ctx, index) {
                                  final en = enrollments[index];
                                  final emp = en['employee'] ?? {};
                                  final empName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
                                  final status = (en['status'] ?? 'enrolled').toString().toUpperCase();
                                  final progress = en['progress_percentage'] ?? 0;

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.grey200),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primary.withAlpha(26),
                                          child: Text(empName.isNotEmpty ? empName[0] : 'E', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(empName.isEmpty ? 'Employee' : empName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text('${l10n.progressLabel}: $progress% | ${l10n.statusLabel}: $status', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
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