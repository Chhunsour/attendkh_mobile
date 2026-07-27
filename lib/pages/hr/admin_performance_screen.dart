import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart' show DepartmentData;
import 'package:mpg_hr_mobile_app/services/directory_repository.dart' show EmployeeData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Performance & Training', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
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
              tabs: const [Tab(text: 'Reviews'), Tab(text: 'Training')],
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
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit Review' : 'Create Review', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedEmpId.isEmpty ? null : selectedEmpId,
                      decoration: InputDecoration(labelText: 'Employee *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: _employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.firstName} ${e.lastName}'))).toList(),
                      onChanged: isEdit ? null : (val) => setSheetState(() => selectedEmpId = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedType,
                      decoration: InputDecoration(labelText: 'Review Type *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: const [
                        DropdownMenuItem(value: 'manager', child: Text('Manager Review')),
                        DropdownMenuItem(value: 'self', child: Text('Self Review')),
                        DropdownMenuItem(value: 'peer', child: Text('Peer Review')),
                        DropdownMenuItem(value: '360', child: Text('360 Review')),
                      ],
                      onChanged: (val) => setSheetState(() => selectedType = val ?? 'manager'),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(controller: periodCtrl, decoration: InputDecoration(labelText: 'Review Period (e.g. Q1 2026) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final init = pStartCtrl.text.isNotEmpty ? (DateTime.tryParse(pStartCtrl.text) ?? DateTime.now()) : DateTime.now();
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
                                setSheetState(() => pStartCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
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
                                setSheetState(() => pEndCtrl.text = picked.toIso8601String().substring(0, 10));
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
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
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Review Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
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
                      decoration: InputDecoration(labelText: 'Status *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'acknowledged', child: Text('Acknowledged')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) => setSheetState(() => selectedStatus = val ?? 'draft'),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: strengthsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Key Strengths', hintText: 'Key accomplishments...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: improvementsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Areas for Improvement', hintText: 'Areas to develop or improve...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: goalsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Future Goals & Objectives', hintText: 'Target goals for next period...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: 'Manager / Reviewer Comments', hintText: 'Final reviewer comments...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (selectedEmpId.isEmpty || periodCtrl.text.trim().isEmpty || (pStartCtrl.text.isEmpty && !isEdit) || (pEndCtrl.text.isEmpty && !isEdit)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.danger)); 
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
                        child: Text(isEdit ? 'Update Review' : 'Create Review', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
          padding: const EdgeInsets.all(16), color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Search employees...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onSubmitted: (val) { _search = val; _fetchData(); },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: _type,
                      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Types')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'self', child: Text('Self')),
                        DropdownMenuItem(value: 'peer', child: Text('Peer')),
                        DropdownMenuItem(value: '360', child: Text('360')),
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
                        const DropdownMenuItem(value: 'all', child: Text('All Periods')),
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
          child: _loading ? const LoadingIndicator(message: 'Loading Reviews...') : _reviews.isEmpty ? const Center(child: Text('No reviews found.', style: TextStyle(color: AppColors.grey500))) : ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: _reviews.length, separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = _reviews[i];
              final statusColor = r.status == 'completed' ? AppColors.success : r.status == 'submitted' ? AppColors.info : AppColors.warning;
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)), padding: const EdgeInsets.all(16),
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
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Text('Period: ${r.reviewPeriod ?? 'N/A'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        if (r.overallRating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text('${r.overallRating} / 5', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (r.status == 'draft') TextButton.icon(onPressed: () async { await _repo.submitReview(r.id); _fetchData(); }, icon: const Icon(Icons.send, size: 16), label: const Text('Submit')),
                        TextButton.icon(onPressed: () => _showForm(r), icon: const Icon(Icons.edit, size: 16), label: const Text('Edit')),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Rating',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600),
              ),
              Text(
                rating > 0 ? '$rating / 5' : 'Not Rated',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rating > 0 ? const Color(0xFFD97706) : AppColors.grey400,
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
                    color: isFilled ? const Color(0xFFF59E0B) : AppColors.grey400,
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
      setState(() {
        _trainings = res.trainings;
        _departments = res.departments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _showForm([TrainingCourseData? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: isEdit ? item.title : '');
    final descCtrl = TextEditingController(text: isEdit ? (item.description ?? '') : '');
    String selectedDeptId = isEdit ? (item.departmentId?.toString() ?? '') : '';
    String selectedLevel = isEdit ? (item.level ?? 'beginner') : 'beginner';
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
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? 'Edit Training' : 'Create Training', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
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
                        child: Container(
                          width: double.infinity, height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.grey100, borderRadius: BorderRadius.circular(16),
                            image: coverImageFile != null ? DecorationImage(image: FileImage(coverImageFile!), fit: BoxFit.cover) : 
                                   (item?.coverImage != null ? DecorationImage(image: NetworkImage('http://192.168.100.252:8000${item!.coverImage}'), fit: BoxFit.cover) : null),
                          ),
                          child: (coverImageFile == null && item?.coverImage == null) ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, size: 48, color: AppColors.grey400), SizedBox(height: 8), Text('Tap to upload cover image', style: TextStyle(color: AppColors.grey500))]) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: selectedDeptId.isEmpty ? null : selectedDeptId,
                      decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Company-Wide')),
                        ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                      ],
                      onChanged: (val) => setSheetState(() => selectedDeptId = val ?? ''),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      isExpanded: true, initialValue: selectedLevel,
                      decoration: InputDecoration(labelText: 'Level', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                      ],
                      onChanged: (val) => setSheetState(() => selectedLevel = val ?? 'beginner'),
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.danger)); 
                            return;
                          }
                          try {
                            final data = {
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                              if (selectedDeptId.isNotEmpty) 'department_id': selectedDeptId,
                              'level': selectedLevel,
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
                        child: Text(isEdit ? 'Update Training' : 'Create Training', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
            padding: const EdgeInsets.all(16), color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Search trainings...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  onSubmitted: (val) { _search = val; _fetchData(); },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true, initialValue: _departmentId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                    const DropdownMenuItem(value: 'company-wide', child: Text('Company-Wide')),
                    ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                  ],
                  onChanged: (val) { if (val != null) { _departmentId = val; _fetchData(); } },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading ? const LoadingIndicator(message: 'Loading Trainings...') : _trainings.isEmpty ? const Center(child: Text('No trainings found.', style: TextStyle(color: AppColors.grey500))) : ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: _trainings.length, separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = _trainings[i];
                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey200)), padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.coverImage != null)
                        Container(
                          width: double.infinity, height: 120, margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage('http://192.168.100.252:8000${t.coverImage}'), fit: BoxFit.cover)),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(6)), child: Text(t.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.info))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(t.description ?? 'No description', style: TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Text(t.department?.name ?? 'Company-Wide', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Text(t.level?.toUpperCase() ?? 'BEGINNER', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () => _showForm(t), icon: const Icon(Icons.edit, size: 16), label: const Text('Edit')),
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
}