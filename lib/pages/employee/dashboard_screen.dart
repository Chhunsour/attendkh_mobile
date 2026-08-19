import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
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

      // Fast seed from last known position so we don't wait on GPS lock
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && mounted && _currentPosition == null) {
          setState(() => _currentPosition = lastPos);
        }
      } catch (_) {}

      // Background dashboard location update
      final pos =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          ).catchError((_) async {
            return (await Geolocator.getLastKnownPosition())!;
          });
      if (mounted) setState(() => _currentPosition = pos);

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription =
          Geolocator.getPositionStream(
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
    if (_currentPosition == null ||
        profile.branchLat == null ||
        profile.branchLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      profile.branchLat!,
      profile.branchLng!,
    );
  }

  Future<void> _handleSimpleClockOut({
    required AppLocalizations l10n,
    bool isOvertime = false,
  }) async {
    bool proceed = false;
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOvertime
                        ? Colors.deepPurple.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: isOvertime ? Colors.deepPurple : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isOvertime
                      ? l10n.confirmOvertimeClockOut
                      : l10n.confirmClockOut,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isOvertime ? l10n.endOvertimeConfirm : l10n.clockOutConfirm,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                    fontSize: 14,
                    height: 1.4,
                  ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.grey300,
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.grey700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          backgroundColor: isOvertime
                              ? Colors.deepPurple
                              : AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.clockOutBtn,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          SnackBar(
            content: Text(
              isOvertime ? l10n.overtimeEnded : l10n.clockedOutSuccess,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
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
          SnackBar(
            content: Text('❌ $msg'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildClockButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isClockedIn,
    ProfileData? profile,
    TodayAttendance? today,
    bool isLateNow,
  ) {
    final bool isRegularCompleted =
        today?.clockIn != null && today?.clockOut != null;

    if (isRegularCompleted) {
      return const SizedBox(); // Shift completed, no more clocking in/out.
    }

    final isClockingOut = isClockedIn;
    const isOvertimeAction = false;

    return _SwipeToClockButton(
      l10n: l10n,
      isClockedIn: isClockingOut,
      isOvertime: isOvertimeAction,
      isLoading: _isClocking,
      onSwipe: () async {
        if (_isClocking) return;

        // If clocking out, skip geofence and photo
        if (isClockingOut) {
          _handleSimpleClockOut(l10n: l10n, isOvertime: isOvertimeAction);
          return;
        }

        // If clocking in, ensure location is fetched or attempted
        if (_currentPosition == null) {
          setState(() => _isClocking = true);
          try {
            _currentPosition =
                await Geolocator.getLastKnownPosition() ??
                await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: Duration(seconds: 4),
                  ),
                );
          } catch (_) {}
          if (mounted) setState(() => _isClocking = false);
        }

        final pos = _currentPosition;
        final lat = pos?.latitude ?? profile?.branchLat ?? 0.0;
        final lng = pos?.longitude ?? profile?.branchLng ?? 0.0;
        final distance = profile != null
            ? (_calculateDistance(profile) ?? 0.0)
            : 0.0;

        final args = ClockInArgs(
          isClockIn: true,
          isOvertime: isOvertimeAction,
          branchName: profile?.branchName ?? l10n.unknownLocation,
          latitude: lat,
          longitude: lng,
          distance: distance,
          radius: profile?.branchRadius,
          isLateNow: isLateNow,
        );

        if (context.mounted) {
          context.push(AppRoutes.clockIn, extra: args);
        }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 20,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helloPrefix + (authState.userName ?? 'User'),
              style: TextStyle(
                fontSize: 20,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            Text(
              authState.companyName ?? l10n.myCompany,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : AppColors.grey700,
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
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
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.grey200,
                    width: 1.5,
                  ),
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
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: todayAsync.when(
        data: (today) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          onRefresh: () async {
            await Future.wait([
              ref.refresh(todayAttendanceProvider.future),
              ref.refresh(employeeDashboardSummaryProvider.future),
              ref.refresh(profileProvider.future),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeading(context, today),
                const SizedBox(height: 18),
                summaryAsync.maybeWhen(
                  data: (summary) =>
                      _buildAnnouncements(summary, l10n: l10n, isUrgent: true),
                  orElse: () => const SizedBox(),
                ),
                _buildClockCard(
                  context,
                  ref,
                  l10n,
                  today,
                  profileAsync: profileAsync,
                ),
                summaryAsync.maybeWhen(
                  data: (summary) =>
                      _buildLateWarningBanner(summary, l10n: l10n),
                  orElse: () => const SizedBox(),
                ),
                const SizedBox(height: 26),
                summaryAsync.when(
                  data: (summary) =>
                      _buildSummarySection(context, summary, l10n),
                  loading: () => const _OverviewSkeleton(),
                  error: (e, _) => const SizedBox(),
                ),
                const SizedBox(height: 26),
                _buildQuickActionsGrid(
                  context,
                  l10n,
                  authState.isBranchManager,
                ),
                const SizedBox(height: 26),
                summaryAsync.maybeWhen(
                  data: (summary) =>
                      _buildAnnouncements(summary, l10n: l10n, isUrgent: false),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
        loading: () => _DashboardLoadingState(message: l10n.loadingDashboard),
        error: (error, _) => _buildError(context, ref, l10n, error.toString()),
      ),
    );
  }

  Widget _buildDateHeading(BuildContext context, TodayAttendance? today) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = today?.date != null
        ? DateTime.tryParse(today!.date!)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE').format(date).toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('d MMMM yyyy').format(date),
          style: TextStyle(
            fontSize: 23,
            height: 1.1,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
      ],
    );
  }

  Widget _buildLateWarningBanner(
    Map<String, dynamic> summary, {
    required AppLocalizations l10n,
  }) {
    final int lateCount = summary['late_count'] ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (lateCount < 3) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2615) : AppColors.warningLight,
        border: Border.all(
          color: isDark ? const Color(0xFF8D6C1E) : AppColors.warning,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isDark ? const Color(0xFFFCD34D) : AppColors.warning,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lateWarningTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFCD34D) : AppColors.warning,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.lateWarningDesc1 +
                      lateCount.toString() +
                      l10n.lateWarningDesc2,
                  style: TextStyle(
                    color: isDark ? AppColors.grey300 : AppColors.grey800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    Map<String, dynamic> summary,
    AppLocalizations l10n,
  ) {
    final leaveBalance = summary['leave_balance']?.toString() ?? '0';
    final nextShift = formatShiftTime(summary['next_shift']?.toString());
    final recentPayslip =
        summary['recent_payslip']?.toString() ?? l10n.noPayslipsYet;
    final pendingExpenses = '${summary['pending_expenses_count'] ?? 0}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, title: l10n.overview),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.upcomingLeaves,
                value: leaveBalance,
                unit: l10n.days,
                badge: l10n.available,
                icon: Icons.event_available_rounded,
                color: AppColors.secondary,
                onTap: () => context.push(AppRoutes.leaveList),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.myShift,
                value: nextShift,
                badge: l10n.today,
                icon: Icons.access_time_rounded,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.attendance),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.recentPayslip,
                value: recentPayslip,
                icon: Icons.payments_outlined,
                color: AppColors.success,
                onTap: () => context.push(AppRoutes.payslip),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.pendingExpenses,
                value: pendingExpenses,
                icon: Icons.receipt_long_outlined,
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.expense),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeading(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 3,
          height: 17,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? unit,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double valueSize = value.length > 14
        ? 15
        : (value.length > 8 ? 19 : 26);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _statSurface(
          context,
          color: color,
          child: SizedBox(
            height: 128,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statIcon(context, icon, color),
                      if (badge != null)
                        Flexible(child: _statBadge(context, badge, color))
                      else
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: valueSize,
                            height: 1.15,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                      ),
                      if (unit != null) ...[
                        const SizedBox(width: 5),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statSurface(
    BuildContext context, {
    required Color color,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.07 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _statIcon(
    BuildContext context,
    IconData icon,
    Color color, {
    double size = 18,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.badgeText(context, color), size: size),
    );
  }

  Widget _statBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.badgeBg(context, color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.badgeText(context, color),
        ),
      ),
    );
  }

  Widget _buildAnnouncements(
    Map<String, dynamic> summary, {
    required AppLocalizations l10n,
    required bool isUrgent,
  }) {
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: targetAnnouncements.map((a) {
          final accent = a.priority == 'urgent'
              ? (isDark ? const Color(0xFFFCA5A5) : AppColors.danger)
              : (isDark ? const Color(0xFFFCD34D) : AppColors.warning);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? accent.withValues(alpha: 0.11)
                  : accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.campaign_outlined, color: accent, size: 19),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.content,
                        style: TextStyle(
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, title: l10n.companyAnnouncements),
        const SizedBox(height: 14),
        ...targetAnnouncements.map(
          (a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.content,
                  style: TextStyle(
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a.publishedAt != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(a.publishedAt!).toLocal())
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClockCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    TodayAttendance? today, {
    required AsyncValue<ProfileData> profileAsync,
  }) {
    final summaryAsync = ref.watch(employeeDashboardSummaryProvider);
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;
    final isCompleted = today?.clockIn != null && today?.clockOut != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isClockedIn
        ? const Color(0xFF34D399)
        : (isCompleted ? const Color(0xFFFBBF24) : const Color(0xFF7DB5FF));
    final baseColor = isDark
        ? const Color(0xFF15223A)
        : const Color(0xFF111C33);
    final statusIcon = isClockedIn
        ? Icons.timer_outlined
        : (isCompleted
              ? Icons.check_circle_outline_rounded
              : Icons.wb_sunny_outlined);
    final statusLabel = isClockedIn ? 'LIVE' : (isCompleted ? 'DONE' : 'READY');

    String? caption;
    String headline;
    String? meta;
    if (isClockedIn) {
      caption = l10n.clockedInAt.trim();
      headline = _formatTime(today!.clockIn);
      if (today.workHours != null) {
        meta = l10n.activeDuration + formatDurationHours(today.workHours);
      }
    } else if (isCompleted) {
      caption = l10n.shiftCompleted;
      headline = today!.workHours != null
          ? formatDurationHours(today.workHours)
          : _formatTime(today.clockOut);
      meta = '${_formatTime(today.clockIn)}  ·  ${_formatTime(today.clockOut)}';
    } else {
      headline = l10n.readyToWork;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, accent, 0.13)!],
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: isDark ? 0.45 : 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: accent, size: 19),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.myShift,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _statusBadge(statusLabel, accent),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (caption != null) ...[
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      headline,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 33,
                        height: 1.05,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meta,
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  profileAsync.maybeWhen(
                    data: (profile) => _buildClockActionArea(
                      context,
                      ref,
                      l10n,
                      profile,
                      today,
                      isClockedIn,
                      isCompleted,
                      summaryAsync.valueOrNull?['is_late_now'] == true,
                    ),
                    orElse: () => _buildClockButton(
                      context,
                      ref,
                      l10n,
                      isClockedIn,
                      null,
                      today,
                      summaryAsync.valueOrNull?['is_late_now'] == true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockActionArea(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProfileData profile,
    TodayAttendance? today,
    bool isClockedIn,
    bool isCompleted,
    bool isLateNow,
  ) {
    if (_locationPermissionGranted == false && !isClockedIn && !isCompleted) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_disabled_outlined,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.locationAccessDesc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () async {
                LocationPermission permission =
                    await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }
                if (permission == LocationPermission.deniedForever) {
                  await Geolocator.openAppSettings();
                }
                _startLocationTracking();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.enableLocation,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final distance = _calculateDistance(profile);
    final isOutsideRadius =
        profile.branchRadius != null &&
        distance != null &&
        distance > profile.branchRadius!;
    final hasUsableDistance = distance != null && distance < 1000000;
    final distanceLabel = distance != null && profile.branchRadius != null
        ? (hasUsableDistance
              ? '${distance.toStringAsFixed(0)}m / ${profile.branchRadius}m'
              : l10n.locationNeedsAttention)
        : null;
    final warnColor = const Color(0xFFFBBF24);

    final String? hint = isClockedIn
        ? l10n.clockOutAnywhere
        : (isOutsideRadius && hasUsableDistance
              ? l10n.moveCloserToBranch
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOutsideRadius
                  ? warnColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOutsideRadius
                    ? Icons.warning_amber_rounded
                    : Icons.location_on_outlined,
                size: 17,
                color: isOutsideRadius ? warnColor : Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.branchName ?? l10n.unknownLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isOutsideRadius ? warnColor : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (distanceLabel != null)
                Flexible(
                  child: Text(
                    distanceLabel,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOutsideRadius ? warnColor : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (_currentPosition == null && profile.branchLat != null)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _buildClockButton(
          context,
          ref,
          l10n,
          isClockedIn,
          profile,
          today,
          isLateNow,
        ),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    AppLocalizations l10n,
    bool isBranchManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, title: l10n.quickFeatures),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const double spacing = 10;
            const int columns = 4;
            final double tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            Widget tile({
              required String label,
              required IconData icon,
              required Color color,
              required VoidCallback onTap,
            }) {
              return SizedBox(
                width: tileWidth,
                child: _buildActionTile(
                  context,
                  label: label,
                  icon: icon,
                  color: color,
                  onTap: onTap,
                ),
              );
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                if (isBranchManager)
                  tile(
                    label: l10n.managerPortal,
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFF7C83FD),
                    onTap: () => context.push(AppRoutes.companyAdmin),
                  ),
                tile(
                  label: l10n.leaves,
                  icon: Icons.event_note_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push(AppRoutes.leaveList),
                ),
                tile(
                  label: l10n.payslips,
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.payslip),
                ),
                tile(
                  label: l10n.overtime,
                  icon: Icons.more_time_rounded,
                  color: const Color(0xFF7C83FD),
                  onTap: () => context.push(AppRoutes.requestOvertime),
                ),
                tile(
                  label: l10n.expenses,
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.expense),
                ),
                tile(
                  label: l10n.holidays,
                  icon: Icons.celebration_rounded,
                  color: const Color(0xFFE5B94E),
                  onTap: () => context.push(AppRoutes.employeeHolidays),
                ),
                tile(
                  label: l10n.myKpis,
                  icon: Icons.track_changes_rounded,
                  color: const Color(0xFF4EA7D8),
                  onTap: () => context.push(AppRoutes.kpi),
                ),
                tile(
                  label: l10n.training,
                  icon: Icons.school_rounded,
                  color: const Color(0xFF9A8CF5),
                  onTap: () => context.push(AppRoutes.training),
                ),
                tile(
                  label: l10n.more,
                  icon: Icons.grid_view_rounded,
                  color: AppColors.grey500,
                  onTap: () =>
                      _showMoreServicesSheet(context, l10n, isBranchManager),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.badgeText(context, color),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.grey200 : AppColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreServicesSheet(
    BuildContext context,
    AppLocalizations l10n,
    bool isBranchManager,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.companyServices,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF6366F1,
                    ).withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Color(0xFF6366F1),
                  ),
                ),
                title: Text(
                  l10n.companyRules,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                subtitle: Text(
                  l10n.payrollAttendanceRules,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.companyRules);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEC4899,
                    ).withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.policy_rounded,
                    color: Color(0xFFEC4899),
                  ),
                ),
                title: Text(
                  l10n.companyPolicies,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                subtitle: Text(
                  l10n.readAndAcknowledge,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.companyPolicies);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF14B8A6,
                    ).withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Color(0xFF14B8A6),
                  ),
                ),
                title: Text(
                  l10n.companyDocuments,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                subtitle: Text(
                  l10n.viewCompanyDocuments,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.companyDocuments);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: AppColors.info,
                  ),
                ),
                title: Text(
                  l10n.history,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                subtitle: Text(
                  l10n.checkAttendanceLogs,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.grey500 : AppColors.grey400,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.attendance);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(
              l10n.failedToLoadDashboard,
              style: const TextStyle(color: AppColors.grey600),
            ),
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

class _DashboardLoadingState extends StatelessWidget {
  final String message;

  const _DashboardLoadingState({required this.message});

  @override
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBlock(width: 90, height: 12),
          const SizedBox(height: 10),
          const _SkeletonBlock(width: 200, height: 24),
          const SizedBox(height: 20),
          const _SkeletonBlock(width: double.infinity, height: 252, radius: 24),
          const SizedBox(height: 28),
          const _SkeletonBlock(width: 130, height: 18),
          const SizedBox(height: 14),
          const _OverviewSkeleton(),
          const SizedBox(height: 24),
          Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonBlock(height: 128, radius: 20)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBlock(height: 128, radius: 20)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonBlock(height: 128, radius: 20)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBlock(height: 128, radius: 20)),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : AppColors.grey200,
        borderRadius: BorderRadius.circular(radius),
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

  const _SwipeToClockButton({
    required this.l10n,
    required this.isClockedIn,
    required this.onSwipe,
    this.isOvertime = false,
    this.isLoading = false,
  });

  @override
  State<_SwipeToClockButton> createState() => _SwipeToClockButtonState();
}

class _SwipeToClockButtonState extends State<_SwipeToClockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _dragValue = 0.0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _animController.addListener(() {
      setState(() {
        _dragValue = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target, {VoidCallback? onComplete}) {
    _animation = Tween<double>(begin: _dragValue, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.reset();
    _animController.forward().then((_) {
      onComplete?.call();
    });
  }

  void _triggerSuccess(double maxDrag) {
    if (_triggered) return;
    _triggered = true;
    HapticFeedback.mediumImpact();
    _animateTo(
      maxDrag,
      onComplete: () {
        widget.onSwipe();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _animateTo(
              0.0,
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _triggered = false;
                  });
                }
              },
            );
          }
        });
      },
    );
  }

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
        ? (widget.isClockedIn
              ? widget.l10n.swipeToClockOutOT
              : widget.l10n.swipeToClockInOT)
        : (widget.isClockedIn
              ? widget.l10n.swipeToClockOut
              : widget.l10n.swipeToClockIn);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = (constraints.maxWidth - height).clamp(
          0.0,
          double.infinity,
        );
        final double progress = maxDrag > 0
            ? (_dragValue / maxDrag).clamp(0.0, 1.0)
            : 0.0;
        final double textOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              if (_triggered || widget.isLoading) return;
              _animController.stop();
            },
            onHorizontalDragUpdate: (details) {
              if (_triggered || widget.isLoading) return;
              setState(() {
                _dragValue = (_dragValue + details.delta.dx).clamp(
                  0.0,
                  maxDrag,
                );
              });
            },
            onHorizontalDragEnd: (details) {
              if (_triggered || widget.isLoading) return;
              final velocity = details.primaryVelocity ?? 0.0;
              // Trigger if dragged over 45% or swiped with forward velocity
              if (_dragValue > maxDrag * 0.45 || velocity > 250) {
                _triggerSuccess(maxDrag);
              } else {
                _animateTo(0.0);
              }
            },
            onHorizontalDragCancel: () {
              if (!_triggered && !widget.isLoading) {
                _animateTo(0.0);
              }
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Active Fill Background behind thumb
                if (_dragValue > 0)
                  Container(
                    width: _dragValue + height,
                    height: height,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),

                // Center Text and Hint Chevrons
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Opacity(
                          opacity: textOpacity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                ),

                // Draggable / Sliding Knob
                Positioned(
                  left: _dragValue,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.isLoading || _triggered
                          ? null
                          : () => _triggerSuccess(maxDrag),
                      borderRadius: BorderRadius.circular(height / 2),
                      child: Container(
                        width: height,
                        height: height,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _triggered
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
