import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'widgets/admin_attendance/corrections_tab.dart';
import 'widgets/admin_attendance/daily_logs_tab.dart';
import 'widgets/admin_attendance/manual_attendance_modal.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen>
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

  void _openAddManualModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManualAttendanceModal(
        onSaved: () {
          ref.invalidate(allAttendanceLogsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider);
    final pendingCorrections = correctionsAsync.maybeWhen(
      data: (items) => items.where((i) => i.status == 'pending').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.attendanceLogsTitle,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Manual Attendance',
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF10B981),
            ),
            onPressed: () => _openAddManualModal(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.grey700),
            onPressed: () {
              ref.invalidate(allAttendanceLogsProvider);
              ref.invalidate(attendanceCorrectionsProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface(context),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF10B981),
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: const Color(0xFF10B981),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabDailyLogs),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.tabCorrections),
                      if (pendingCorrections > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCorrections',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [DailyLogsTab(), CorrectionsTab()],
      ),
    );
  }
}
