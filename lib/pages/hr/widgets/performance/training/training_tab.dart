import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/performance_repository.dart';
import 'package:attendkh/services/documents_repository.dart' show DepartmentData;
import 'package:attendkh/services/directory_repository.dart' show DirectoryRepository, EmployeeData;
import 'package:attendkh/utils/image_compressor.dart';
import 'package:attendkh/components/custom_date_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/pages/hr/widgets/performance/shared/chip_style.dart';

class TrainingTab extends StatefulWidget {
  const TrainingTab({super.key});

  @override
  State<TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<TrainingTab> {
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

  final TextEditingController _searchCtrl = TextEditingController();
  bool _debouncing = false;

  void _debounceSearch() {
    if (_debouncing) return;
    _debouncing = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      _debouncing = false;
      _fetchData();
    });
  }

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
      final res = await _repo.getTrainings(search: _search, departmentId: _departmentId, page: _currentPage);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    }
  }

  void _changePage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    setState(() => _currentPage = page);
    _fetchData();
  }

  // ── Style Helpers ──────────────────────────────────────────────────────────
  ChipStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'published': return const ChipStyle(AppColors.primaryLight, AppColors.primary, AppColors.primaryLight);
      case 'ongoing': return const ChipStyle(AppColors.warningLight, AppColors.warning, AppColors.warningLight);
      case 'completed': return const ChipStyle(AppColors.successLight, AppColors.success, AppColors.successLight);
      case 'cancelled': return const ChipStyle(AppColors.dangerLight, AppColors.danger, AppColors.dangerLight);
      case 'draft':
      default: return const ChipStyle(AppColors.grey100, AppColors.grey700, AppColors.grey300);
    }
  }

  ChipStyle _levelStyle(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner': return const ChipStyle(AppColors.successLight, AppColors.success, AppColors.successLight);
      case 'intermediate': return const ChipStyle(AppColors.warningLight, AppColors.warning, AppColors.warningLight);
      case 'advanced': return const ChipStyle(AppColors.dangerLight, AppColors.danger, AppColors.dangerLight);
      default: return const ChipStyle(AppColors.grey100, AppColors.grey700, AppColors.grey300);
    }
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt != null) return DateFormat('dd MMM yyyy').format(dt);
    return d.split(' ')[0];
  }

  // ── Info Chip ──────────────────────────────────────────────────────────────
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── KPI Metrics ────────────────────────────────────────────────────────────
  Widget _buildMetricsOverview(AppLocalizations l10n) {
    final active = _trainings.where((t) => t.status == 'ongoing' || t.status == 'published').length;
    final completed = _trainings.where((t) => t.status == 'completed').length;
    final companyWide = _trainings.where((t) => t.departmentId == null).length;
    final metrics = [
      (Icons.menu_book_rounded, l10n.totalCourses, '$_total', const Color(0xFFEFF6FF), const Color(0xFF3B82F6), null as Color?),
      (Icons.auto_awesome_rounded, l10n.activePrograms, '$active', const Color(0xFFECFDF5), AppColors.success, AppColors.success as Color?),
      (Icons.check_circle_outline_rounded, l10n.completedPrograms, '$completed', const Color(0xFFF5F3FF), const Color(0xFF8B5CF6), null as Color?),
      (Icons.business_rounded, l10n.companyWide, '$companyWide', const Color(0xFFFFF7ED), AppColors.warning, null as Color?),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.3,
        children: metrics.map((m) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context).withAlpha(80)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: m.$4, borderRadius: BorderRadius.circular(10)), child: Icon(m.$1, color: m.$5, size: 17)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.$3, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: m.$6 ?? AppColors.textPrimary(context), height: 1.1)),
                      Text(m.$2, style: const TextStyle(fontSize: 10, color: AppColors.grey500, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context).withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) { setState(() => _search = val); _debounceSearch(); },
            decoration: InputDecoration(
              hintText: l10n.searchTrainingsHint,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey400), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); _fetchData(); })
                  : null,
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border(context).withAlpha(100))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _departmentId,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey500, size: 20),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.allDepartments)),
                  DropdownMenuItem(value: 'company-wide', child: Text(l10n.companyWide)),
                  ..._departments.map((d) => DropdownMenuItem(value: d.id.toString(), child: Text(d.name))),
                ],
                onChanged: (val) { if (val != null) { setState(() => _departmentId = val); _fetchData(); } },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Training Card ──────────────────────────────────────────────────────────
  Widget _buildTrainingCard(TrainingCourseData t, AppLocalizations l10n) {
    final s = _statusStyle(t.status);
    final lv = _levelStyle(t.level);
    final storageUrl = t.coverImage != null && t.coverImage!.isNotEmpty
        ? (t.coverImage!.startsWith('http') ? t.coverImage! : '${DioClient.storageUrl}/${t.coverImage!.startsWith('/') ? t.coverImage!.substring(1) : t.coverImage!}')
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context).withAlpha(90)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image hero with overlaid badges
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 150,
                child: storageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: storageUrl, fit: BoxFit.cover, memCacheWidth: 700, memCacheHeight: 400,
                        placeholder: (ctx, url) => Container(color: AppColors.grey100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                        errorWidget: (ctx, url, err) => Container(
                          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)])),
                          child: const Center(child: Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary)),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)])),
                        child: const Center(child: Icon(Icons.menu_book_rounded, size: 52, color: AppColors.primary)),
                      ),
              ),
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: lv.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: lv.border.withAlpha(80))),
                  child: Text((t.level ?? 'BEGINNER').toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: lv.text, letterSpacing: 0.6)),
                ),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: s.border.withAlpha(80))),
                  child: Text(t.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: s.text, letterSpacing: 0.6)),
                ),
              ),
            ],
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(t.department?.name ?? l10n.companyWide, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(height: 8),
                Text(t.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary(context), height: 1.25), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (t.description != null && t.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(t.description!, style: const TextStyle(fontSize: 12, color: AppColors.grey500, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    if (t.instructor != null && t.instructor!.isNotEmpty) _buildInfoChip(Icons.person_outline_rounded, t.instructor!, AppColors.primary),
                    if (t.durationHours != null) _buildInfoChip(Icons.access_time_rounded, '${t.durationHours}h', AppColors.warning),
                    if (t.location != null && t.location!.isNotEmpty) _buildInfoChip(Icons.location_on_outlined, t.location!, const Color(0xFF3B82F6)),
                    if (t.maxParticipants != null) _buildInfoChip(Icons.group_outlined, '${l10n.capacityLabel} ${t.maxParticipants}', const Color(0xFF8B5CF6)),
                    if (t.startDate != null && t.endDate != null) _buildInfoChip(Icons.date_range_rounded, '${_formatDate(t.startDate!)} – ${_formatDate(t.endDate!)}', AppColors.grey500),
                  ],
                ),
              ],
            ),
          ),

          // Action bar
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.backgroundLight, border: Border(top: BorderSide(color: AppColors.border(context).withAlpha(80)))),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showEnrollmentSheet(t),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(AppLocalizations.of(context)?.enrollments ?? 'Enrollments', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(onTap: () => _showForm(t), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey600))),
                const SizedBox(width: 8),
                InkWell(onTap: () => _deleteTraining(t), borderRadius: BorderRadius.circular(10), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context).withAlpha(80))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $_from–$_to of $_total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.grey500)),
          Row(
            children: [
              _paginationBtn(Icons.chevron_left, _currentPage > 1 ? () => _changePage(_currentPage - 1) : null),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: Text('$_currentPage / $_lastPage', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              _paginationBtn(Icons.chevron_right, _currentPage < _lastPage ? () => _changePage(_currentPage + 1) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: onTap != null ? AppColors.primaryLight : AppColors.grey100, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: onTap != null ? AppColors.primary : AppColors.grey300),
      ),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteTraining(TrainingCourseData t) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteTrainingTitle),
        content: Text(l10n.deleteTrainingConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteTitle, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.deleteTraining(t.id);
        _fetchData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.trainingDeletedSuccess), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  // ── Create / Edit Form Sheet ───────────────────────────────────────────────
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
        builder: (ctx, setSheetState) => Padding(
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
                  Text(isEdit ? l10n.editTrainingTitle : l10n.createTrainingTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                  const SizedBox(height: 24),
                  // Cover image picker
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
                          width: double.infinity, height: 160, color: AppColors.grey100,
                          child: coverImageFile != null
                              ? Image.file(coverImageFile!, fit: BoxFit.cover)
                              : (item?.coverImage != null && item!.coverImage!.isNotEmpty)
                              ? CachedNetworkImage(imageUrl: item.coverImage!, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 400, placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)), errorWidget: (ctx, url, err) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.image, size: 48, color: AppColors.grey400), const SizedBox(height: 8), Text(l10n.replaceCoverImage, style: const TextStyle(color: AppColors.grey500))]))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.image, size: 48, color: AppColors.grey400), const SizedBox(height: 8), Text(l10n.uploadCoverImage, style: const TextStyle(color: AppColors.grey500))]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: l10n.titleFieldLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedDeptId.isEmpty ? null : selectedDeptId,
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
                          items: [DropdownMenuItem(value: 'beginner', child: Text(l10n.levelBeginner)), DropdownMenuItem(value: 'intermediate', child: Text(l10n.levelIntermediate)), DropdownMenuItem(value: 'advanced', child: Text(l10n.levelAdvanced))],
                          onChanged: (val) => setSheetState(() => selectedLevel = val ?? 'beginner'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true, initialValue: selectedStatus,
                          decoration: InputDecoration(labelText: l10n.statusLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: [DropdownMenuItem(value: 'draft', child: Text(l10n.statusDraft)), DropdownMenuItem(value: 'published', child: Text(l10n.statusPublished)), DropdownMenuItem(value: 'ongoing', child: Text(l10n.statusOngoing)), DropdownMenuItem(value: 'completed', child: Text(l10n.statusCompleted)), DropdownMenuItem(value: 'cancelled', child: Text(l10n.statusCancelled))],
                          onChanged: (val) => setSheetState(() => selectedStatus = val ?? 'draft'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.durationHours, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: maxParticipantsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.maxCapacity, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextField(controller: instructorCtrl, decoration: InputDecoration(labelText: l10n.instructorName, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: locationCtrl, decoration: InputDecoration(labelText: l10n.locationLink, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _buildDatePicker(ctx: ctx, label: l10n.startDateLabel, ctrl: startDateCtrl, setSheetState: setSheetState, l10n: l10n)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDatePicker(ctx: ctx, label: l10n.endDateLabel, ctrl: endDateCtrl, setSheetState: setSheetState, l10n: l10n)),
                  ]),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                          if (isEdit) { await _repo.updateTraining(item.id, data, coverImagePath: coverImageFile?.path); } else { await _repo.createTraining(data, coverImagePath: coverImageFile?.path); }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchData();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                        }
                      },
                      child: Text(isEdit ? l10n.saveChangesBtn : l10n.createTrainingTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required BuildContext ctx, required String label, required TextEditingController ctrl, required StateSetter setSheetState, required AppLocalizations l10n}) {
    return InkWell(
      onTap: () async {
        final init = ctrl.text.isNotEmpty ? (DateTime.tryParse(ctrl.text) ?? DateTime.now()) : DateTime.now();
        final picked = await showCustomDatePicker(context, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2030));
        if (picked != null) setSheetState(() => ctrl.text = picked.toIso8601String().substring(0, 10));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                const SizedBox(height: 4),
                Text(
                  ctrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(ctrl.text)) : l10n.selectDatePrompt,
                  style: TextStyle(fontSize: 13, fontWeight: ctrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400, color: ctrl.text.isNotEmpty ? AppColors.grey900 : AppColors.grey400),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Enrollment Sheet ───────────────────────────────────────────────────────
  void _showEnrollmentSheet(TrainingCourseData t) {
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
          final l10n = AppLocalizations.of(context)!;
            void fetchEnrollments() async {
              try {
                final list = await _repo.getTrainingEnrollments(t.id);
                setSheetState(() { enrollments = list; loadingEnrollments = false; });
              } catch (e) {
                setSheetState(() => loadingEnrollments = false);
              }
            }
            if (loadingEnrollments) fetchEnrollments();

            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${l10n.enrollmentsTitle}: ${t.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedEmpIdToEnroll,
                          decoration: InputDecoration(hintText: l10n.selectEmployeeToEnroll, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: _employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.fullName} ${e.khmerName}'))).toList(),
                          onChanged: (val) => setSheetState(() => selectedEmpIdToEnroll = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        onPressed: selectedEmpIdToEnroll == null
                            ? null
                            : () async {
                                try {
                                  await _repo.enrollEmployee(t.id, int.parse(selectedEmpIdToEnroll!));
                                  setSheetState(() { selectedEmpIdToEnroll = null; loadingEnrollments = true; });
                                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.employeeEnrolledSuccess), backgroundColor: AppColors.success));
                                } catch (e) {
                                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
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
                                decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(l10n.newTraining, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: RefreshIndicator(
        onRefresh: () async { _currentPage = 1; await _fetchData(); },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _buildMetricsOverview(l10n),
            _buildFilterBar(l10n),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else if (_trainings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.menu_book_rounded, size: 32, color: AppColors.primary)),
                      const SizedBox(height: 14),
                      Text(l10n.noTrainings, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                      const SizedBox(height: 4),
                      Text(l10n.createFirstTrainingCourse, style: const TextStyle(fontSize: 12, color: AppColors.grey500), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trainings.length + (_lastPage > 1 ? 1 : 0),
                  separatorBuilder: (_, i) => i == _trainings.length - 1 ? const SizedBox.shrink() : const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    if (i == _trainings.length) return _buildPagination();
                    return _buildTrainingCard(_trainings[i], l10n);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}