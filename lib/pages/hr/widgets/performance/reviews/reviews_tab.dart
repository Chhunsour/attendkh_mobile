import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/performance_repository.dart';
import 'package:mpg_hr_mobile_app/services/directory_repository.dart' show EmployeeData;
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/components/custom_date_picker.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/performance/shared/chip_style.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/performance/shared/star_rating_picker.dart';

class ReviewsTab extends StatefulWidget {
  const ReviewsTab({super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  bool _loading = true;
  List<PerformanceReviewData> _reviews = [];
  List<String> _periods = [];
  List<EmployeeData> _employees = [];

  final TextEditingController _searchCtrl = TextEditingController();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await _repo.getReviews(
        search: _searchCtrl.text.trim(),
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

  ChipStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const ChipStyle(Color(0xFFF1F5F9), Color(0xFF64748B), Color(0xFFCBD5E1));
      case 'submitted':
        return const ChipStyle(Color(0xFFFFFBEB), Color(0xFFD97706), Color(0xFFFDE68A));
      case 'acknowledged':
        return const ChipStyle(Color(0xFFEFF6FF), Color(0xFF2563EB), Color(0xFFBFDBFE));
      case 'completed':
        return const ChipStyle(Color(0xFFECFDF5), Color(0xFF059669), Color(0xFFA7F3D0));
      default:
        return const ChipStyle(Color(0xFFF1F5F9), Color(0xFF64748B), Color(0xFFCBD5E1));
    }
  }

  ChipStyle _typeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'self':
        return const ChipStyle(Color(0xFFFAF5FF), Color(0xFF9333EA), Color(0xFFE9D5FF));
      case 'manager':
        return const ChipStyle(Color(0xFFEFF6FF), Color(0xFF2563EB), Color(0xFFBFDBFE));
      case 'peer':
        return const ChipStyle(Color(0xFFF0FDFA), Color(0xFF0D9488), Color(0xFF99F6E4));
      case '360':
        return const ChipStyle(Color(0xFFEEF2FF), Color(0xFF4F46E5), Color(0xFFC7D2FE));
      default:
        return const ChipStyle(Color(0xFFF1F5F9), Color(0xFF64748B), Color(0xFFCBD5E1));
    }
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt != null) return DateFormat('dd MMM yyyy').format(dt);
    return d.split(' ')[0];
  }

  // ── KPI Metrics ────────────────────────────────────────────────────────────
  Widget _buildMetricsOverview() {
    final totalCount = _total > 0 ? _total : _reviews.length;
    final completedCount = _reviews.where((r) => r.status.toLowerCase() == 'completed' || r.status.toLowerCase() == 'acknowledged').length;
    final pendingCount = _reviews.where((r) => r.status.toLowerCase() == 'draft' || r.status.toLowerCase() == 'submitted').length;
    final ratedReviews = _reviews.where((r) => r.overallRating != null && r.overallRating! > 0).toList();
    final avgRating = ratedReviews.isNotEmpty
        ? ratedReviews.fold<double>(0.0, (sum, r) => sum + r.overallRating!) / ratedReviews.length
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: _buildKpiCard(title: 'Total Reviews', value: totalCount.toString(), icon: Icons.assignment_outlined, color: AppColors.primary, bg: AppColors.primary.withAlpha(16))),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard(title: 'Avg Score', value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', icon: Icons.star_rounded, color: const Color(0xFFD97706), bg: const Color(0xFFFFFBEB), suffix: avgRating > 0 ? ' ★' : '')),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard(title: 'Completed', value: completedCount.toString(), icon: Icons.check_circle_outline_rounded, color: const Color(0xFF059669), bg: const Color(0xFFECFDF5))),
          const SizedBox(width: 8),
          Expanded(child: _buildKpiCard(title: 'Pending', value: pendingCount.toString(), icon: Icons.schedule_rounded, color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED))),
        ],
      ),
    );
  }

  Widget _buildKpiCard({required String title, required String value, required IconData icon, required Color color, required Color bg, String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context).withAlpha(80)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary(context))),
              if (suffix.isNotEmpty) Text(suffix, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context).withAlpha(120)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) { _currentPage = 1; _fetchData(); },
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search employee name, Khmer name, ID...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.grey400),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.grey400),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.grey400),
                              onPressed: () { _searchCtrl.clear(); _currentPage = 1; _fetchData(); },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Filter by Review Type',
                initialValue: _type,
                onSelected: (val) { setState(() { _type = val; _currentPage = 1; }); _fetchData(); },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'all', child: Text('All Types')),
                  PopupMenuItem(value: 'manager', child: Text('Manager Review')),
                  PopupMenuItem(value: 'self', child: Text('Self Review')),
                  PopupMenuItem(value: 'peer', child: Text('Peer Review')),
                  PopupMenuItem(value: '360', child: Text('360 Review')),
                ],
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _type != 'all' ? AppColors.primary.withAlpha(20) : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _type != 'all' ? AppColors.primary : AppColors.border(context).withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list_rounded, size: 18, color: _type != 'all' ? AppColors.primary : AppColors.grey600),
                      if (_type != 'all') ...[
                        const SizedBox(width: 4),
                        Text(_type.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodPill('all', 'All Periods'),
                ..._periods.map((p) => _buildPeriodPill(p, p)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(String key, String label) {
    final isSelected = _period == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          if (_period != key) { setState(() { _period = key; _currentPage = 1; }); _fetchData(); }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border(context).withAlpha(100)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Review Card ────────────────────────────────────────────────────────────
  Widget _buildReviewCard(PerformanceReviewData r) {
    final s = _statusStyle(r.status);
    final t = _typeStyle(r.reviewType);
    final empName = '${r.employee?.fullName ?? ''} ${r.employee?.khmerName ?? ''}'.trim();
    final displayName = empName.isNotEmpty ? empName : 'Unnamed Employee';
    final initials = (r.employee != null && r.employee!.fullName.trim().isNotEmpty)
        ? r.employee!.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'PR';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context).withAlpha(90)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showView(r),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.border)),
                    child: Center(child: Text(initials, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: t.text))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (r.employee?.employeeId != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                                child: Text('#${r.employee!.employeeId}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: AppColors.grey700)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: t.border)),
                              child: Text(r.reviewType.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: t.text)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: s.border)),
                    child: Text(r.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.text, letterSpacing: 0.3)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: [
                  if (r.overallRating != null && r.overallRating! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFDE68A))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 3),
                        Text('${r.overallRating} / 5.0', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Not rated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                    ),
                  if (r.reviewPeriod != null && r.reviewPeriod!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border(context).withAlpha(120))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.grey500),
                        const SizedBox(width: 4),
                        Text(r.reviewPeriod!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                      ]),
                    ),
                  if (r.periodStart != null && r.periodEnd != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_formatDate(r.periodStart!)} – ${_formatDate(r.periodEnd!)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (r.reviewer != null)
                    Expanded(child: Text('By: ${r.reviewer!.fullName}', style: const TextStyle(fontSize: 11, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis))
                  else
                    const Spacer(),
                  InkWell(
                    onTap: () => _showView(r),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.visibility_outlined, size: 14, color: AppColors.grey700),
                        SizedBox(width: 4),
                        Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey700)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (r.status.toLowerCase() == 'draft') ...[
                    InkWell(
                      onTap: () async { await _repo.submitReview(r.id); _fetchData(); },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFA7F3D0))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.send_rounded, size: 13, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text('Submit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (r.status.toLowerCase() == 'submitted') ...[
                    InkWell(
                      onTap: () => _acknowledgeReview(r),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF2563EB)),
                          SizedBox(width: 4),
                          Text('Acknowledge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.grey600),
                    style: IconButton.styleFrom(padding: const EdgeInsets.all(6), minimumSize: const Size(28, 28), backgroundColor: AppColors.grey100),
                    tooltip: 'Edit Review',
                    onPressed: () => _showForm(r),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                    style: IconButton.styleFrom(padding: const EdgeInsets.all(6), minimumSize: const Size(28, 28), backgroundColor: AppColors.danger.withAlpha(15)),
                    tooltip: 'Delete',
                    onPressed: () => _deleteReview(r),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $_from to $_to of $_total reviews', style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null, color: AppColors.primary),
              Text('$_currentPage / $_lastPage', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.grey700)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < _lastPage ? () => _changePage(_currentPage + 1) : null, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _acknowledgeReview(PerformanceReviewData r) async {
    try {
      await _repo.acknowledgeReview(r.id);
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteTitle, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.deleteReview(r.id);
        _fetchData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  // ── Detail Sheet ───────────────────────────────────────────────────────────
  void _showView(PerformanceReviewData r) {
    final s = _statusStyle(r.status);
    final t = _typeStyle(r.reviewType);
    final empName = '${r.employee?.fullName ?? ''} ${r.employee?.khmerName ?? ''}'.trim();
    final displayName = empName.isNotEmpty ? empName : 'Unnamed Employee';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assessment_outlined, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review Appraisal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary(context))),
                        Text(displayName, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppColors.grey100, padding: const EdgeInsets.all(8)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.grey200),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context).withAlpha(100))),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: _buildModalStatTile(label: 'Review Type', value: r.reviewType.toUpperCase(), badgeColor: t.bg, badgeTextColor: t.text)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildModalStatTile(label: 'Status', value: r.status.toUpperCase(), badgeColor: s.bg, badgeTextColor: s.text)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _buildModalStatTile(label: 'Period', value: r.reviewPeriod ?? 'N/A')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildModalStatTile(label: 'Review Date', value: r.reviewDate != null ? _formatDate(r.reviewDate!) : 'N/A')),
                          ]),
                          if (r.overallRating != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Overall Rating Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                  Row(children: [
                                    ...List.generate(5, (index) => Icon(Icons.star_rounded, size: 16, color: index < r.overallRating! ? const Color(0xFFD97706) : AppColors.grey300)),
                                    const SizedBox(width: 6),
                                    Text('${r.overallRating} / 5.0', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStyledViewSection(title: 'Strengths & Key Accomplishments', content: r.strengths, icon: Icons.thumb_up_alt_outlined, accentColor: const Color(0xFF059669), bgColor: const Color(0xFFECFDF5)),
                    _buildStyledViewSection(title: 'Areas for Improvement & Development', content: r.areasForImprovement, icon: Icons.trending_up_rounded, accentColor: const Color(0xFFD97706), bgColor: const Color(0xFFFFFBEB)),
                    _buildStyledViewSection(title: 'Goals for Next Evaluation Period', content: r.goals, icon: Icons.flag_outlined, accentColor: const Color(0xFF7C3AED), bgColor: const Color(0xFFF5F3FF)),
                    _buildStyledViewSection(title: 'Final Reviewer Comments & Feedback', content: r.comments, icon: Icons.comment_outlined, accentColor: AppColors.primary, bgColor: AppColors.primary.withAlpha(15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStatTile({required String label, required String value, Color? badgeColor, Color? badgeTextColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (badgeColor != null && badgeTextColor != null)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)), child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeTextColor)))
        else
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
      ],
    );
  }

  Widget _buildStyledViewSection({required String title, required String? content, required IconData icon, required Color accentColor, required Color bgColor}) {
    final hasContent = content != null && content.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border(context).withAlpha(90))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: accentColor)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)))),
            ]),
            const SizedBox(height: 10),
            Text(hasContent ? content : 'No notes or information provided.', style: TextStyle(fontSize: 12.5, color: hasContent ? AppColors.grey800 : AppColors.grey400, height: 1.45)),
          ],
        ),
      ),
    );
  }

  // ── Create / Edit Form Sheet ───────────────────────────────────────────────
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
    final pStartCtrl = TextEditingController(text: isEdit ? (item.periodStart ?? '') : '');
    final pEndCtrl = TextEditingController(text: isEdit ? (item.periodEnd ?? '') : '');
    final revDateCtrl = TextEditingController(text: isEdit ? (item.reviewDate ?? '') : DateTime.now().toString().substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEdit ? l10n.editReviewTitle : l10n.createReviewTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary(context))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, size: 20), style: IconButton.styleFrom(backgroundColor: AppColors.grey100, padding: const EdgeInsets.all(8))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedEmpId.isEmpty ? null : selectedEmpId,
                    decoration: InputDecoration(labelText: l10n.employeeRequired, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                    items: _employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.fullName} ${e.khmerName ?? ''}'.trim()))).toList(),
                    onChanged: isEdit ? null : (val) => setSheetState(() => selectedEmpId = val ?? ''),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedType,
                    decoration: InputDecoration(labelText: l10n.reviewTypeRequired, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                    items: [
                      DropdownMenuItem(value: 'manager', child: Text(l10n.reviewTypeManager)),
                      DropdownMenuItem(value: 'self', child: Text(l10n.reviewTypeSelf)),
                      DropdownMenuItem(value: 'peer', child: Text(l10n.reviewTypePeer)),
                      DropdownMenuItem(value: '360', child: Text(l10n.reviewType360)),
                    ],
                    onChanged: (val) => setSheetState(() => selectedType = val ?? 'manager'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: periodCtrl, decoration: InputDecoration(labelText: l10n.periodRequired, hintText: l10n.periodHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker(ctx: ctx, label: l10n.periodStartRequired, ctrl: pStartCtrl, setSheetState: setSheetState)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDatePicker(ctx: ctx, label: l10n.periodEndRequired, ctrl: pEndCtrl, setSheetState: setSheetState)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(ctx: ctx, label: l10n.reviewDateRequired, ctrl: revDateCtrl, setSheetState: setSheetState),
                  const SizedBox(height: 16),
                  StarRatingPicker(rating: selectedRating, onChanged: (val) => setSheetState(() => selectedRating = val)),
                  const SizedBox(height: 16),
                  TextField(controller: strengthsCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.strengthsOptional, hintText: 'Key accomplishments and strengths...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  TextField(controller: improvementsCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.areasForImprovementOptional, hintText: 'Areas to develop or improve...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  TextField(controller: goalsCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.goalsOptional, hintText: 'Target goals for next evaluation period...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 16),
                  TextField(controller: commentsCtrl, maxLines: 2, decoration: InputDecoration(labelText: l10n.commentsOptional, hintText: 'Final reviewer comments and feedback...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 2, shadowColor: AppColors.primary.withAlpha(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
                          };
                          if (isEdit) { await _repo.updateReview(item.id, data); } else { await _repo.createReview(data); }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchData();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
                        }
                      },
                      child: Text(isEdit ? l10n.saveChangesBtn : l10n.createReviewTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildDatePicker({required BuildContext ctx, required String label, required TextEditingController ctrl, required StateSetter setSheetState}) {
    return InkWell(
      onTap: () async {
        final init = ctrl.text.isNotEmpty ? (DateTime.tryParse(ctrl.text) ?? DateTime.now()) : DateTime.now();
        final picked = await showCustomDatePicker(context, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2030));
        if (picked != null) setSheetState(() => ctrl.text = picked.toIso8601String().substring(0, 10));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border(context).withAlpha(120))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey600)),
                const SizedBox(height: 4),
                Text(
                  ctrl.text.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.parse(ctrl.text)) : 'Select date...',
                  style: TextStyle(fontSize: 12.5, fontWeight: ctrl.text.isNotEmpty ? FontWeight.w700 : FontWeight.w400, color: ctrl.text.isNotEmpty ? AppColors.textPrimary(context) : AppColors.grey400),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
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
        label: const Text('New Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: RefreshIndicator(
        onRefresh: () async { _currentPage = 1; await _fetchData(); },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            _buildMetricsOverview(),
            _buildFilterBar(),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingIndicator(message: 'Loading performance reviews...'))
            else if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.assessment_outlined, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(l10n.noReviews, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                      const SizedBox(height: 4),
                      const Text('Create your first appraisal or adjust filters', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reviews.length + (_lastPage > 1 ? 1 : 0),
                  separatorBuilder: (_, i) => i == _reviews.length - 1 ? const SizedBox.shrink() : const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == _reviews.length) return _buildPagination();
                    return _buildReviewCard(_reviews[i]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
