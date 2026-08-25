// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/admin_system_health_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminSystemHealthProvider =
    FutureProvider.autoDispose<AdminSystemHealthData>((ref) {
  return AdminSystemHealthRepository().getHealth();
});

class AdminSystemHealthScreen extends ConsumerStatefulWidget {
  const AdminSystemHealthScreen({super.key});

  @override
  ConsumerState<AdminSystemHealthScreen> createState() =>
      _AdminSystemHealthScreenState();
}

class _AdminSystemHealthScreenState
    extends ConsumerState<AdminSystemHealthScreen> {
  bool _isClearing = false;
  bool _isRetrying = false;

  Future<void> _handleClearCache() async {
    setState(() => _isClearing = true);
    try {
      await AdminSystemHealthRepository().clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server cache & views cleared successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(adminSystemHealthProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Future<void> _handleRetryJobs() async {
    setState(() => _isRetrying = true);
    try {
      await AdminSystemHealthRepository().retryJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All failed queue jobs queued for retry.'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(adminSystemHealthProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry jobs: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(adminSystemHealthProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'System Health & Server',
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
            onPressed: () => ref.invalidate(adminSystemHealthProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminSystemHealthProvider),
        child: healthAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to connect to health monitor: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminSystemHealthProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => _buildBody(data, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AdminSystemHealthData data, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Systems Operational',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cloudways Node • PHP ${data.server.phpVersion} • Laravel ${data.server.laravelVersion}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grid of 4 cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            // Database
            _card(
              title: 'Database Size',
              value: '${data.database.sizeMb} MB',
              subtitle: '${data.database.tablesCount} tables',
              icon: Icons.storage_rounded,
              color: const Color(0xFF10B981),
            ),

            // Server Memory
            _card(
              title: 'PHP Memory',
              value: '${data.server.memoryUsageMb} MB',
              subtitle: 'Peak: ${data.server.memoryPeakMb} MB',
              icon: Icons.memory_rounded,
              color: const Color(0xFF3B82F6),
            ),

            // Queue Jobs
            _card(
              title: 'Queue Workers',
              value: '${data.queue.pendingJobs} pending',
              subtitle: '${data.queue.failedJobs} failed',
              icon: Icons.bolt_rounded,
              color: data.queue.failedJobs > 0 ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9),
            ),

            // Storage
            _card(
              title: 'Public Storage',
              value: '${data.storage.usedMb} MB',
              subtitle: 'Disk: ${data.storage.disk}',
              icon: Icons.folder_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Server Actions Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Server Optimization Tools',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isClearing ? null : _handleClearCache,
                  icon: _isClearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: Text(_isClearing ? 'Flushing cache...' : 'Flush Cache & Views (optimize:clear)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (data.queue.failedJobs > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRetrying ? null : _handleRetryJobs,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.replay_rounded, size: 18, color: AppColors.danger),
                    label: Text(
                      _isRetrying ? 'Retrying jobs...' : 'Retry All Failed Queue Jobs (${data.queue.failedJobs})',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
