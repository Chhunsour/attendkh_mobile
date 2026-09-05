// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/services/admin_login_history_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/l10n/app_localizations.dart';

final adminLoginHistoryProvider =
    FutureProvider.autoDispose<AdminLoginHistoryResult>((ref) {
  return AdminLoginHistoryRepository().getHistories();
});

class AdminLoginHistoryScreen extends ConsumerStatefulWidget {
  const AdminLoginHistoryScreen({super.key});

  @override
  ConsumerState<AdminLoginHistoryScreen> createState() =>
      _AdminLoginHistoryScreenState();
}

class _AdminLoginHistoryScreenState
    extends ConsumerState<AdminLoginHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  String _statusFilter = 'all';
  String _platformFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(adminLoginHistoryProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Login History & Security',
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
            onPressed: () => ref.invalidate(adminLoginHistoryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminLoginHistoryProvider),
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load login history: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminLoginHistoryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (result) => _buildContent(result, l10n),
        ),
      ),
    );
  }

  Widget _buildContent(AdminLoginHistoryResult result, AppLocalizations l10n) {
    final filtered = result.histories.where((h) {
      if (_statusFilter != 'all' && h.status != _statusFilter) return false;
      if (_platformFilter != 'all') {
        if (_platformFilter == 'mobile' &&
            !h.platform.contains('mobile') &&
            h.platform != 'api') {
          return false;
        }
        if (_platformFilter == 'web' && h.platform != 'web') return false;
      }
      if (_searchTerm.isNotEmpty) {
        final q = _searchTerm.toLowerCase();
        final email = (h.email ?? '').toLowerCase();
        final name = (h.userName ?? '').toLowerCase();
        final ip = (h.ipAddress ?? '').toLowerCase();
        final device = (h.device ?? '').toLowerCase();
        return email.contains(q) ||
            name.contains(q) ||
            ip.contains(q) ||
            device.contains(q);
      }
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Top Metric Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildMetricRow(result.metrics),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search IP, email, or device...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: (v) => setState(() => _searchTerm = v.trim()),
            ),
          ),
        ),

        // Filter Chips
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Logins'),
                const SizedBox(width: 8),
                _buildFilterChip('success', '🟢 Success'),
                const SizedBox(width: 8),
                _buildFilterChip('failed', '🔴 Failed Attempts'),
                const SizedBox(width: 8),
                _buildPlatformChip('mobile', '📱 Mobile App'),
                const SizedBox(width: 8),
                _buildPlatformChip('web', '🌐 Web Browser'),
              ],
            ),
          ),
        ),

        // History List
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    Text(
                      _searchTerm.isNotEmpty
                          ? 'No matching login records'
                          : 'No login activity recorded yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildHistoryCard(filtered[i]),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricRow(AdminLoginMetrics m) {
    return Row(
      children: [
        Expanded(child: _metricCard('Today', '${m.totalToday}', const Color(0xFF3B82F6), Icons.key_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Success', '${m.successToday}', const Color(0xFF10B981), Icons.check_circle_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Failed', '${m.failedToday}', const Color(0xFFEF4444), Icons.gpp_bad_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _metricCard('Mobile', '${m.mobileToday}', const Color(0xFF8B5CF6), Icons.smartphone_rounded)),
      ],
    );
  }

  Widget _metricCard(String title, String val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String val, String label) {
    final active = _statusFilter == val;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      selected: active,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: AppColors.surface(context),
      onSelected: (_) => setState(() => _statusFilter = val),
    );
  }

  Widget _buildPlatformChip(String val, String label) {
    final active = _platformFilter == val;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      selected: active,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: AppColors.surface(context),
      onSelected: (_) => setState(() => _platformFilter = _platformFilter == val ? 'all' : val),
    );
  }

  Widget _buildHistoryCard(AdminLoginHistory h) {
    final isSuccess = h.status == 'success';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                  size: 16,
                  color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.userName ?? h.email ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (h.companyName != null)
                      Text(
                        h.companyName!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  h.ipAddress ?? '127.0.0.1',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                h.platform.contains('mobile') ? Icons.smartphone_rounded : Icons.desktop_windows_rounded,
                size: 13,
                color: AppColors.grey500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${h.device ?? 'Device'} • ${h.platform.toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                h.createdAt != null
                    ? h.createdAt!.replaceFirst('T', ' ').substring(0, 16)
                    : '-',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
