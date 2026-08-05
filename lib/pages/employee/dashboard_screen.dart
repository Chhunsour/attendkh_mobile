import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/providers/dashboard_provider.dart';
import 'package:mpg_hr_mobile_app/pages/employee/clock_in_screen.dart';
import 'package:mpg_hr_mobile_app/services/announcements_repository.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  bool _isClocking = false;
  Position? _currentPosition;
  bool? _locationPermissionGranted;
  StreamSubscription<Position>? _positionStreamSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationTracking();
    
    // Check if notifications are disabled and prompt if necessary
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FcmService.instance.checkAndPromptNotificationPermission(context);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when returning from settings
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    
    try {


      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationPermissionGranted = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _locationPermissionGranted = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationPermissionGranted = false);
        return;
      }

      if (mounted) setState(() => _locationPermissionGranted = true);


      // Use medium accuracy for initial background dashboard location check to avoid blocking GPS satellite lock
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      if (mounted) setState(() => _currentPosition = pos);

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 15,
        ),
      ).listen((Position position) {
        if (mounted) setState(() => _currentPosition = position);
      });
    } catch (e) {
      if (mounted) setState(() => _locationPermissionGranted = false);
      AppLogger.e('Location tracking error', e);
    }
  }

  double? _calculateDistance(ProfileData profile) {
    if (_currentPosition == null || profile.branchLat == null || profile.branchLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      profile.branchLat!,
      profile.branchLng!,
    );
  }

  Future<void> _handleSimpleClockOut({required AppLocalizations l10n, bool isOvertime = false}) async {
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOvertime ? Colors.deepPurple.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, size: 40, color: isOvertime ? Colors.deepPurple : AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(isOvertime ? l10n.confirmOvertimeClockOut : l10n.confirmClockOut, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
              const SizedBox(height: 12),
              Text(
                isOvertime ? l10n.endOvertimeConfirm : l10n.clockOutConfirm, 
                textAlign: TextAlign.center, 
                style: const TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        proceed = false;
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.grey300),
                      ),
                      child: Text(l10n.cancel, style: const TextStyle(color: AppColors.grey700, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        proceed = true;
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOvertime ? Colors.deepPurple : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(l10n.clockOutBtn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!proceed) return;

    setState(() => _isClocking = true);

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      if (isOvertime) {
        await repo.overtimeOut(
          lat: _currentPosition?.latitude ?? 0.0,
          lng: _currentPosition?.longitude ?? 0.0,
          deviceId: 'app',
        );
      } else {
        await repo.clockOut(
          lat: _currentPosition?.latitude ?? 0.0,
          lng: _currentPosition?.longitude ?? 0.0,
        );
      }
      ref.invalidate(todayAttendanceProvider);
      if (mounted) setState(() => _isClocking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isOvertime ? l10n.overtimeEnded : l10n.clockedOutSuccess), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isClocking = false);
      String msg = l10n.clockOutFailed;
      if (e is AppException) {
        msg = e.message;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildClockButton(BuildContext context, WidgetRef ref, AppLocalizations l10n, bool isClockedIn, ProfileData? profile, TodayAttendance? today) {
    final bool isRegularCompleted = today?.clockIn != null && today?.clockOut != null;
    final bool isOvertimeIn = today?.overtimeIn != null && today?.overtimeOut == null;
    final bool isOvertimeCompleted = today?.overtimeIn != null && today?.overtimeOut != null;

    if (isOvertimeCompleted) {
      return const SizedBox(); // Should not show any button
    }

    final isClockingOut = isClockedIn || isOvertimeIn;
    final isOvertimeAction = isRegularCompleted && !isOvertimeCompleted;

    return _SwipeToClockButton(
      l10n: l10n,
      isClockedIn: isClockingOut,
      isOvertime: isOvertimeAction,
      isLoading: _isClocking,
      onSwipe: () {
        if (_isClocking) return;

        // If clocking out, skip geofence and photo
        if (isClockingOut) {
          _handleSimpleClockOut(l10n: l10n, isOvertime: isOvertimeAction);
          return;
        }

        // If clocking in, enforce location and new selfie screen
        if (_currentPosition == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.waitingForLocation)));
          return;
        }

        final args = ClockInArgs(
          isClockIn: true,
          isOvertime: isOvertimeAction,
          branchName: profile?.branchName ?? l10n.unknownLocation,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          distance: profile != null ? (_calculateDistance(profile) ?? 0) : 0,
          radius: profile?.branchRadius,
        );

        context.push(AppRoutes.clockIn, extra: args);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayAsync = ref.watch(todayAttendanceProvider);
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final summaryAsync = ref.watch(employeeDashboardSummaryProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helloPrefix + (authState.userName ?? 'User'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
            ),
            Text(
              authState.companyName ?? l10n.myCompany,
              style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.grey700),
                onPressed: () async {
                  await context.push(AppRoutes.notifications);
                  ref.invalidate(unreadCountProvider);
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 8),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: profileAsync.value?.photoUrl != null
                      ? CachedNetworkImageProvider(
                          profileAsync.value!.photoUrl!,
                          maxWidth: 120,
                          maxHeight: 120,
                        )
                      : null,
                  child: profileAsync.value?.photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                      : null,
                ),
              ),
            ),
          )
        ],
      ),
      body: todayAsync.when(
        data: (today) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryAsync.maybeWhen(
                data: (summary) => Column(
                  children: [
                    _buildAnnouncements(summary, l10n: l10n, isUrgent: true),
                    _buildClockCard(context, ref, l10n, today, profileAsync: profileAsync),
                    _buildLateWarningBanner(summary, l10n: l10n),
                  ],
                ),
                orElse: () => _buildClockCard(context, ref, l10n, today, profileAsync: profileAsync),
              ),
              
              const SizedBox(height: 28),

              summaryAsync.maybeWhen(
                data: (summary) => _buildAnnouncements(summary, l10n: l10n, isUrgent: false),
                orElse: () => const SizedBox(),
              ),

              Text(
                l10n.quickFeatures,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800),
              ),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(context, l10n, authState.isBranchManager),

              const SizedBox(height: 28),
              
              summaryAsync.when(
                data: (summary) => _buildSummarySection(context, summary, l10n),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => const SizedBox(),
              ),
            ],
          ),
        ),
        loading: () => LoadingIndicator(message: l10n.loadingDashboard),
        error: (error, _) => _buildError(context, ref, l10n, error.toString()),
      ),
    );
  }

  Widget _buildLateWarningBanner(Map<String, dynamic> summary, {required AppLocalizations l10n}) {
    final int lateCount = summary['late_count'] ?? 0;
    
    if (lateCount < 3) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lateWarningTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  l10n.lateWarningDesc1 + lateCount.toString() + l10n.lateWarningDesc2,
                  style: const TextStyle(color: AppColors.grey800, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, Map<String, dynamic> summary, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.overview,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: [
            _buildSummaryCard(
              title: l10n.upcomingLeaves,
              count: (summary['upcoming_leaves'] as List?)?.length.toString() ?? '0',
              icon: Icons.event_available,
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.leaveList),
            ),
            _buildSummaryCard(
              title: l10n.recentActivity,
              count: (summary['recent_attendance'] as List?)?.length.toString() ?? '0',
              icon: Icons.how_to_reg,
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.attendance),
            ),
            _buildSummaryCard(
              title: l10n.activeTrainings,
              count: (summary['active_trainings'] as List?)?.length.toString() ?? '0',
              icon: Icons.school,
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.training),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnnouncements(Map<String, dynamic> summary, {required AppLocalizations l10n, required bool isUrgent}) {
    if (summary['announcements'] == null) return const SizedBox();
    
    final allAnnouncements = (summary['announcements'] as List)
        .map((e) => AnnouncementData.fromJson(e as Map<String, dynamic>))
        .toList();
        
    final targetAnnouncements = allAnnouncements.where((a) {
      if (isUrgent) {
        return a.priority == 'urgent' || a.priority == 'high';
      }
      return a.priority != 'urgent' && a.priority != 'high';
    }).toList();

    if (targetAnnouncements.isEmpty) return const SizedBox();

    if (isUrgent) {
      return Column(
        children: targetAnnouncements.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: a.priority == 'urgent' ? Colors.red.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.priority == 'urgent' ? Colors.red.shade200 : Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign, color: a.priority == 'urgent' ? Colors.red.shade700 : Colors.orange.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: a.priority == 'urgent' ? Colors.red.shade900 : Colors.orange.shade900)),
                    const SizedBox(height: 4),
                    Text(a.content, style: TextStyle(color: a.priority == 'urgent' ? Colors.red.shade800 : Colors.orange.shade800)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.companyAnnouncements,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
        ),
        const SizedBox(height: 12),
        ...targetAnnouncements.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey900)),
              const SizedBox(height: 4),
              Text(a.content, style: const TextStyle(color: AppColors.grey700)),
              const SizedBox(height: 8),
              Text(
                a.publishedAt != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(a.publishedAt!).toLocal()) : '',
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryCard({required String title, required String count, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockCard(BuildContext context, WidgetRef ref, AppLocalizations l10n, TodayAttendance? today, {required AsyncValue<ProfileData> profileAsync}) {
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;
    final isCompleted = today?.clockIn != null && today?.clockOut != null;
    final isOvertimeIn = today?.overtimeIn != null && today?.overtimeOut == null;
    final isOvertimeCompleted = today?.overtimeIn != null && today?.overtimeOut != null;

    final Color cardColor = isOvertimeIn
        ? Colors.deepPurple
        : isOvertimeCompleted 
            ? AppColors.grey800
            : isClockedIn
                ? AppColors.success
                : (isCompleted ? Colors.deepOrange : AppColors.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
            child: Icon(
              isOvertimeIn || isClockedIn
                  ? Icons.timer_outlined
                  : (isOvertimeCompleted || isCompleted ? Icons.check_circle : Icons.access_time_rounded),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            today?.date != null
                ? DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(today!.date!).toLocal())
                : DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 0.5),
          ),
          profileAsync.maybeWhen(
            data: (profile) => profile.branchName != null 
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(profile.branchName!, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : const SizedBox(height: 6),
            orElse: () => const SizedBox(height: 6),
          ),
          if (isOvertimeIn) ...[
            Text(l10n.overtimeStartedAt + _formatTime(today!.overtimeIn!), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          ] else if (isOvertimeCompleted) ...[
            Text(l10n.overtimeCompleted, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ] else if (isClockedIn) ...[
            Text(l10n.clockedInAt + _formatTime(today!.clockIn!), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            if (today.workHours != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                child: Text(l10n.activeDuration + formatDurationHours(today.workHours), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ] else if (isCompleted) ...[
            Text(l10n.shiftCompleted, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            if (today!.workHours != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                child: Text(l10n.worked + formatDurationHours(today.workHours), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ] else ...[
            Text(l10n.readyToWork, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
          const SizedBox(height: 24),

          if (!isOvertimeCompleted)
            profileAsync.maybeWhen(
              data: (profile) {
                if (_locationPermissionGranted == false && !isClockedIn && !isOvertimeIn && !isCompleted) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Icon(Icons.location_disabled, color: Colors.white70, size: 32),
                        const SizedBox(height: 8),
                        Text(l10n.locationAccessRequired, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(l10n.locationAccessDesc, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }
                            if (permission == LocationPermission.deniedForever) {
                              // Only open settings if permanently denied
                              await Geolocator.openAppSettings();
                            }
                            _startLocationTracking();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(l10n.enableLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }

                if (profile.branchLat == null || profile.branchLng == null || profile.branchRadius == null) {
                  return _buildClockButton(context, ref, l10n, isClockedIn, profile, today);
                }
                
                final distance = _calculateDistance(profile);
                if (distance == null && !isClockedIn && !isOvertimeIn && !isCompleted) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Text(l10n.calculatingLocation, style: const TextStyle(color: Colors.white70)),
                   );
                }

                if (isClockedIn || isOvertimeIn || isCompleted || (distance != null && distance <= profile.branchRadius!)) {
                  return Column(
                    children: [
                      if (!isClockedIn && !isOvertimeIn && !isCompleted)
                        Text('${l10n.withinRadiusPrefix}${distance?.toStringAsFixed(0) ?? '0'}m / ${profile.branchRadius}m)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      if (isClockedIn || isOvertimeIn)
                        Text(l10n.clockOutAnywhere, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      _buildClockButton(context, ref, l10n, isClockedIn, profile, today),
                    ],
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Icon(Icons.location_off, color: Colors.white70),
                        const SizedBox(height: 8),
                        Text(l10n.youAreAwayPrefix + (distance?.toStringAsFixed(0) ?? '0') + l10n.youAreAwaySuffix, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(l10n.mustBeWithinPrefix + profile.branchRadius.toString() + l10n.mustBeWithinSuffix, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
              },
              orElse: () => _buildClockButton(context, ref, l10n, isClockedIn, null, today),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n, bool isBranchManager) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        if (isBranchManager)
          _GridItem(
            title: l10n.managerPortal,
            description: l10n.teamApprovals,
            icon: Icons.admin_panel_settings_outlined,
            color: Colors.deepPurple,
            onTap: () => context.push(AppRoutes.companyAdmin),
          ),
        _GridItem(
          title: l10n.leaves,
          description: l10n.requestOffDays,
          icon: Icons.event_note_outlined,
          color: AppColors.secondary,
          onTap: () => context.push(AppRoutes.leaveList),
        ),
        _GridItem(
          title: l10n.expenses,
          description: l10n.claimReimbursements,
          icon: Icons.receipt_long_outlined,
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.expense),
        ),
        _GridItem(
          title: l10n.payslips,
          description: l10n.viewMonthlyStatements,
          icon: Icons.monetization_on_outlined,
          color: AppColors.success,
          onTap: () => context.push(AppRoutes.payslip),
        ),
        _GridItem(
          title: l10n.history,
          description: l10n.checkAttendanceLogs,
          icon: Icons.history_toggle_off_outlined,
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.attendance),
        ),
        _GridItem(
          title: l10n.training,
          description: l10n.enrollInCourses,
          icon: Icons.school_outlined,
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.training),
        ),
        _GridItem(
          title: l10n.myKpis,
          description: l10n.performanceGoals,
          icon: Icons.track_changes_outlined,
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.kpi),
        ),
        _GridItem(
          title: l10n.holidays,
          description: l10n.companyCalendar,
          icon: Icons.celebration_outlined,
          color: const Color(0xFFEAB308), // Yellow/Gold
          onTap: () => context.push(AppRoutes.employeeHolidays),
        ),

      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(l10n.failedToLoadDashboard, style: const TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(todayAttendanceProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }
}

class _GridItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey900)),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(fontSize: 10, color: AppColors.grey500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToClockButton extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isClockedIn;
  final bool isOvertime;
  final bool isLoading;
  final VoidCallback onSwipe;

  const _SwipeToClockButton({required this.l10n, required this.isClockedIn, required this.onSwipe, this.isOvertime = false, this.isLoading = false});

  @override
  State<_SwipeToClockButton> createState() => _SwipeToClockButtonState();
}

class _SwipeToClockButtonState extends State<_SwipeToClockButton> {
  double _dragValue = 0.0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    const double height = 56.0;
    final color = widget.isOvertime 
        ? (widget.isClockedIn ? Colors.deepPurpleAccent : Colors.white)
        : (widget.isClockedIn ? AppColors.warning : Colors.white);
    
    final iconColor = widget.isOvertime 
        ? (widget.isClockedIn ? Colors.white : Colors.deepPurple)
        : (widget.isClockedIn ? Colors.white : AppColors.primary);
        
    final text = widget.isOvertime
        ? (widget.isClockedIn ? widget.l10n.swipeToClockOutOT : widget.l10n.swipeToClockInOT)
        : (widget.isClockedIn ? widget.l10n.swipeToClockOut : widget.l10n.swipeToClockIn);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - height;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              Center(
                child: widget.isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_triggered || widget.isLoading) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > maxDrag) _dragValue = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_triggered) return;
                    if (_dragValue > maxDrag * 0.8) {
                      setState(() {
                        _dragValue = maxDrag;
                        _triggered = true;
                      });
                      widget.onSwipe();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _dragValue = 0.0;
                            _triggered = false;
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: _dragValue == 0.0 ? const Duration(milliseconds: 200) : Duration.zero,
                    width: height,
                    height: height,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: iconColor, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
