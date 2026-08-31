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

/// Where the employee stands in their day. Drives the clock button's colour:
/// green = the app wants a swipe, amber = they are on the clock, red = done.
enum _ClockPhase {
  /// Not clocked in yet — early or right on time.
  readyToClockIn,

  /// On the clock, still inside the scheduled window.
  working,

  /// On the clock and the shift end has passed.
  readyToClockOut,

  /// Clocked out for the day.
  done,
}

const double _kActionTileHeight = 92;

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

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
  // The clock button changes colour when the shift end passes, so the hero has
  // to notice the minute turning over on its own.
  Timer? _minuteTicker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationTracking();
    _minuteTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

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
      if (_positionStreamSubscription != null &&
          _positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
      } else {
        _startLocationTracking();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _positionStreamSubscription?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _minuteTicker?.cancel();
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

  /// Reasons people actually leave a Cambodian shift early. Picking one fills
  /// the note box, so the common cases cost a single tap. Mirrors the late
  /// reason picker on the clock-in screen.
  static const List<Map<String, String>> _earlyLeaveReasons = [
    {'icon': '🏥', 'en': 'Sick / Medical', 'km': 'ឈឺ / ពិនិត្យសុខភាព'},
    {
      'icon': '👨‍👩‍👧',
      'en': 'Family Emergency',
      'km': 'ការងារគ្រួសារបន្ទាន់',
    },
    {'icon': '📋', 'en': 'Personal Errand', 'km': 'កិច្ចការផ្ទាល់ខ្លួន'},
    {'icon': '✅', 'en': 'Approved by Manager', 'km': 'ប្រធានអនុញ្ញាត'},
    {'icon': '✏️', 'en': 'Other', 'km': 'ផ្សេងទៀត'},
  ];

  Future<void> _handleSimpleClockOut({
    required AppLocalizations l10n,
    bool isOvertime = false,
  }) async {
    final isKhmerLocale = Localizations.localeOf(context).languageCode == 'km';

    // Overtime has no scheduled end to be early for.
    final earlyMinutes = isOvertime
        ? null
        : minutesUntilShiftEnd(
            ref
                .read(employeeDashboardSummaryProvider)
                .valueOrNull?['next_shift']
                ?.toString(),
          );
    final isEarly = earlyMinutes != null;
    final reasonController = TextEditingController();
    int? selectedReason;

    bool isOtherReason() =>
        selectedReason != null &&
        _earlyLeaveReasons[selectedReason!]['en'] == 'Other';
    // "Other" only counts as a reason once they have written one.
    bool earlyReasonGiven() =>
        selectedReason != null &&
        (!isOtherReason() || reasonController.text.trim().isNotEmpty);
    // What the manager sees: the picked reason, plus any detail they added.
    String earlyReasonText() {
      if (selectedReason == null) return '';
      final detail = reasonController.text.trim();
      if (isOtherReason()) return detail;
      final label = (isKhmerLocale
          ? _earlyLeaveReasons[selectedReason!]['km']
          : _earlyLeaveReasons[selectedReason!]['en'])!;
      return detail.isEmpty ? label : '$label — $detail';
    }

    bool proceed = false;
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final isKhmer = isKhmerLocale;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            // The reason block plus a raised keyboard can outgrow a short screen.
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (isOvertime
                                    ? Colors.deepPurple
                                    : isEarly
                                    ? AppColors.warning
                                    : AppColors.primary)
                                .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarly ? Icons.schedule_rounded : Icons.logout_rounded,
                        size: 40,
                        color: isOvertime
                            ? Colors.deepPurple
                            : isEarly
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isOvertime
                          ? l10n.confirmOvertimeClockOut
                          : isEarly
                          ? l10n.earlyClockOutTitle
                          : l10n.confirmClockOut,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isOvertime
                          ? l10n.endOvertimeConfirm
                          : isEarly
                          ? l10n.earlyClockOutBody(
                              formatDurationMinutes(earlyMinutes),
                            )
                          : l10n.clockOutConfirm,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.grey400 : AppColors.grey600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    if (isEarly) ...[
                      const SizedBox(height: 20),
                      // Same reason picker shape as the clock-in screen, so the
                      // control is already familiar by the time they hit it.
                      DropdownButtonFormField<int>(
                        initialValue: selectedReason,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        hint: Text(
                          l10n.earlyClockOutReasonHint,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.grey500
                                : AppColors.grey500,
                          ),
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark
                              ? AppColors.backgroundDark
                              : AppColors.grey100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: List.generate(_earlyLeaveReasons.length, (i) {
                          final r = _earlyLeaveReasons[i];
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Row(
                              children: [
                                Text(
                                  r['icon']!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    (isKhmer ? r['km'] : r['en'])!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary(ctx),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        onChanged: (i) {
                          if (i == null) return;
                          // The box carries extra detail, not a copy of the
                          // label — a stale note from an earlier pick would
                          // contradict the new one.
                          setDialogState(() {
                            selectedReason = i;
                            reasonController.clear();
                          });
                        },
                      ),

                      // The note box only earns its space once a reason is
                      // picked — and it is the whole point of picking "Other".
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: selectedReason == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: TextField(
                                  controller: reasonController,
                                  minLines: 2,
                                  maxLines: 3,
                                  maxLength: 250,
                                  autofocus: isOtherReason(),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  // The Clock Out button keys off this text.
                                  onChanged: (_) => setDialogState(() {}),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary(ctx),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: isOtherReason()
                                        ? l10n.earlyClockOutOtherHint
                                        : l10n.earlyClockOutDetailHint,
                                    counterText: '',
                                    hintStyle: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? AppColors.grey500
                                          : AppColors.grey400,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.grey100,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
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
                                color: isDark
                                    ? Colors.white
                                    : AppColors.grey700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            // An early clock-out is only allowed with a reason.
                            onPressed: isEarly && !earlyReasonGiven()
                                ? null
                                : () {
                                    proceed = true;
                                    Navigator.pop(ctx);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOvertime
                                  ? Colors.deepPurple
                                  : isEarly
                                  ? AppColors.warning
                                  : AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.clockOutBtn,
                              style: const TextStyle(
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
            ),
          ),
        );
      },
    );

    final earlyReason = earlyReasonText();
    reasonController.dispose();

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
          earlyLeaveReason: isEarly ? earlyReason : null,
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

    // Amber only while the scheduled window is still running; once the end
    // time passes (or we never learned it) the button goes green to invite the
    // clock-out swipe.
    final endMinutes = shiftEndMinutes(
      ref
          .watch(employeeDashboardSummaryProvider)
          .valueOrNull?['next_shift']
          ?.toString(),
    );
    final now = DateTime.now();
    final phase = !isClockingOut
        ? _ClockPhase.readyToClockIn
        : (endMinutes != null && now.hour * 60 + now.minute < endMinutes
              ? _ClockPhase.working
              : _ClockPhase.readyToClockOut);

    return _SwipeToClockButton(
      l10n: l10n,
      isClockedIn: isClockingOut,
      isOvertime: isOvertimeAction,
      phase: phase,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The hero runs under the status bar, so its icons must be light in both
    // themes rather than following the page.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
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
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClockCard(
                    context,
                    ref,
                    l10n,
                    today,
                    profileAsync: profileAsync,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        summaryAsync.maybeWhen(
                          data: (summary) => _buildAnnouncements(
                            summary,
                            l10n: l10n,
                            isUrgent: true,
                          ),
                          orElse: () => const SizedBox(),
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
                          authState.isManager,
                        ),
                        const SizedBox(height: 26),
                        summaryAsync.maybeWhen(
                          data: (summary) => _buildAnnouncements(
                            summary,
                            l10n: l10n,
                            isUrgent: false,
                          ),
                          orElse: () => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          loading: () => _DashboardLoadingState(message: l10n.loadingDashboard),
          error: (error, _) =>
              _buildError(context, ref, l10n, error.toString()),
        ),
      ),
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
    // The start time is the figure people look for; the end is context, so it
    // rides in the unit slot instead of competing at headline size.
    final shiftParts = formatShiftTime(
      summary['next_shift']?.toString(),
    ).split(' – ');
    final recentPayslip = _formatPeriod(
      summary['recent_payslip']?.toString(),
      l10n,
    );
    final pendingExpenses = '${summary['pending_expenses_count'] ?? 0}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, title: l10n.overview),
        const SizedBox(height: 14),
        // One panel split by hairlines rather than four floating cards — the
        // four figures belong to the same glance, so they share one surface.
        _statSurface(
          context,
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _statCell(
                        title: l10n.upcomingLeaves,
                        tint: const Color(0xFF3B82F6),
                        value: leaveBalance,
                        unit: l10n.days,
                        icon: Icons.event_available_rounded,
                        onTap: () => context.push(AppRoutes.leaveList),
                      ),
                    ),
                    _cellDivider(context, vertical: true),
                    Expanded(
                      child: _statCell(
                        title: l10n.myShift,
                        tint: const Color(0xFF8B5CF6),
                        value: shiftParts.first,
                        unit: shiftParts.length == 2
                            ? '– ${shiftParts.last}'
                            : null,
                        icon: Icons.access_time_rounded,
                        onTap: () => context.push(AppRoutes.attendance),
                      ),
                    ),
                  ],
                ),
              ),
              _cellDivider(context),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _statCell(
                        title: l10n.recentPayslip,
                        tint: const Color(0xFF059669),
                        value: recentPayslip,
                        icon: Icons.payments_outlined,
                        onTap: () => context.push(AppRoutes.payslip),
                      ),
                    ),
                    _cellDivider(context, vertical: true),
                    Expanded(
                      child: _statCell(
                        title: l10n.pendingExpenses,
                        tint: const Color(0xFFD97706),
                        value: pendingExpenses,
                        icon: Icons.receipt_long_outlined,
                        onTap: () => context.push(AppRoutes.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "2026-08" is a database value, not a headline. Show it as "Aug 2026".
  String _formatPeriod(String? raw, AppLocalizations l10n) {
    if (raw == null || raw.isEmpty) return l10n.noPayslipsYet;
    final parsed = DateTime.tryParse('$raw-01');
    return parsed == null ? raw : DateFormat('MMM yyyy').format(parsed);
  }

  Widget _cellDivider(BuildContext context, {bool vertical = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.borderDark : AppColors.borderLight;
    return vertical
        ? VerticalDivider(width: 1, thickness: 1, color: color)
        : Divider(height: 1, thickness: 1, color: color);
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

  Widget _statCell({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    String? unit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Three deliberate tiers instead of a sliding scale: a counted number is
    // the headline, a short label is secondary, a long string is a detail.
    final double valueSize = RegExp(r'^\d+$').hasMatch(value)
        ? 27
        : (value.length > 12 ? 15 : 20);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 13, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    // Optical alignment with the first line of the label.
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      icon,
                      size: 15,
                      // Tints are picked for white; dark surfaces need them
                      // lifted or they sink into the panel.
                      color: isDark
                          ? Color.lerp(tint, Colors.white, 0.35)!
                          : tint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ponytail: the cell always lives inside an IntrinsicHeight row,
              // so the Spacer is bounded. It pins every value to the same
              // bottom line even when one label wraps and its neighbour does
              // not — the reason the old grid looked ragged.
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: valueSize,
                          height: 1.1,
                          letterSpacing: -0.4,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
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
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statSurface(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
    final summary = summaryAsync.valueOrNull;
    // The server's is_late_now ignores the branch grace period, so we decide
    // it here against the shift start + grace and only fall back to the flag
    // when there is no readable shift window.
    final lateNow = isLateNow(
      summary?['next_shift']?.toString(),
      int.tryParse(
            '${summary?['late_grace_period_minutes'] ?? summary?['grace_period']}',
          ) ??
          15,
      fallback: summary?['is_late_now'] == true,
    );
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;
    final isCompleted = today?.clockIn != null && today?.clockOut != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isClockedIn
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF93C5FD);
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);
    final statusIcon = isClockedIn
        ? Icons.timer_outlined
        : (isCompleted
              ? Icons.check_circle_outline_rounded
              : Icons.wb_sunny_outlined);
    final lateMinutes = today?.lateMinutes ?? 0;
    final isLate = lateMinutes > 0;

    // Scheduled window, so the big number has something to be measured against.
    final rawShift = summaryAsync.valueOrNull?['next_shift']?.toString();
    final shiftWindow = rawShift == null ? null : formatShiftTime(rawShift);
    // ponytail: the en dash means formatShiftTime produced a real window rather
    // than its untranslated "No shift today" fallback.
    final scheduleLabel = (shiftWindow != null && shiftWindow.contains(' – '))
        ? shiftWindow
        : null;

    final date = today?.date != null
        ? DateTime.tryParse(today!.date!)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    String? caption;
    String headline;
    DateTime? inDt;
    if (isClockedIn) {
      caption = l10n.clockedInAt.trim();
      headline = _formatTime(today!.clockIn);
      inDt = _parseDateTime(today.clockIn, today.date);
    } else if (isCompleted) {
      caption = l10n.shiftCompleted;
      headline = _formatCompletedDuration(today);
      // ponytail: in/out times live in _completedSummary, not a duplicate pill.
    } else {
      headline = l10n.readyToWork;
    }

    // Sculpted slab: the app bar and the shift card are one surface, with a
    // deep scoop out of the bottom-left so the silhouette reads as a shape
    // rather than a box.
    const heroRadius = BorderRadius.vertical(bottom: Radius.circular(32));

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: heroRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, Color.lerp(baseColor, AppColors.primary, 0.6)!],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.34 : 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Concentric rings, cropped by the slab edge.
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 10,
              20,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroGreeting(context, l10n, profileAsync),
                const SizedBox(height: 26),
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
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d MMMM yyyy').format(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildShiftStatusBadge(
                      isClockedIn: isClockedIn,
                      isCompleted: isCompleted,
                      isLate: isLate,
                      lateMinutes: lateMinutes,
                      l10n: l10n,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                if (isCompleted) ...[
                  const SizedBox(height: 14),
                  _completedSummary(l10n, today!, profileAsync.valueOrNull),
                  const SizedBox(height: 16),
                  // The track stays on screen after clock-out, parked at the
                  // far end in red, so the day closes on the same object it
                  // started on instead of the control vanishing.
                  _SwipeToClockButton(
                    l10n: l10n,
                    isClockedIn: true,
                    phase: _ClockPhase.done,
                    onSwipe: () {},
                  ),
                ] else ...[
                  if (isClockedIn && (inDt != null || today?.workHours != null)) ...[
                    const SizedBox(height: 10),
                    _RealtimeActiveDurationBadge(
                      clockInTime: inDt,
                      fallbackWorkHours: today?.workHours,
                      accent: accent,
                      activeDurationLabel: l10n.activeDuration,
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
                      lateNow,
                    ),
                    orElse: () => _buildClockButton(
                      context,
                      ref,
                      l10n,
                      isClockedIn,
                      null,
                      today,
                      lateNow,
                    ),
                  ),
                ],
                if (scheduleLabel != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          scheduleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.70),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    final hasUsableDistance = distance != null && distance < 1000000;
    final isOutsideRadius =
        profile.branchRadius != null &&
        hasUsableDistance &&
        distance > profile.branchRadius!;
    final distanceLabel = hasUsableDistance && profile.branchRadius != null
        ? '${distance.toStringAsFixed(0)}m / ${profile.branchRadius}m'
        : null;
    const warnColor = Color(0xFFFBBF24);

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
        const SizedBox(height: 18),
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

  /// Quiet end-of-day recap: in/out times plus where it happened.
  /// No geofence state here — the shift is already over, nothing to act on.
  Widget _completedSummary(
    AppLocalizations l10n,
    TodayAttendance today,
    ProfileData? profile,
  ) {
    const faint = Color(0x73FFFFFF); // white 45%

    Widget cell(IconData icon, String label, String value, bool alignEnd) {
      final cross = alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start;
      return Expanded(
        child: Column(
          crossAxisAlignment: cross,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: faint),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                      color: faint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              cell(
                Icons.login_rounded,
                l10n.checkInTitle,
                _formatTime(today.clockIn),
                false,
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withValues(alpha: 0.10),
              ),
              cell(
                Icons.logout_rounded,
                l10n.checkOutTitle,
                _formatTime(today.clockOut),
                true,
              ),
            ],
          ),
          if (profile != null) ...[
            Divider(
              height: 21,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.09),
            ),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: faint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.branchName ?? l10n.unknownLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Ticket-stub notches bitten out of both card edges. Positioned relative to
  /// the block it wraps, so it stays aligned whatever the shift state renders.
  /// Greeting, alerts and avatar, riding on the hero instead of a separate bar.
  Widget _buildHeroGreeting(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<ProfileData> profileAsync,
  ) {
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helloPrefix + (authState.userName ?? 'User'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  letterSpacing: -0.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                authState.companyName ?? l10n.myCompany,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () async {
                await context.push(AppRoutes.notifications);
                ref.invalidate(unreadCountProvider);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 19,
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
      ],
    );
  }

  Widget _buildShiftStatusBadge({
    required bool isClockedIn,
    required bool isCompleted,
    required bool isLate,
    required int lateMinutes,
    required AppLocalizations l10n,
  }) {
    if (isLate) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x99FBBF24),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.late} ${formatDurationMinutes(lateMinutes)}',
            style: const TextStyle(
              color: Color(0xFFFDE68A),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
    }

    if (isClockedIn) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingStatusDot(color: Color(0xFF34D399), size: 6.5),
          SizedBox(width: 6),
          Text(
            'On Duty',
            style: TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
    }

    if (isCompleted) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF38BDF8)),
          SizedBox(width: 5),
          Text(
            'Completed',
            style: TextStyle(
              color: Color(0xFFBAE6FD),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.5,
          height: 6.5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.40),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Ready',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // One divided panel instead of six floating cards: fewer borders, and the
  // per-item accent colour (previously computed then ignored) does the work
  // of telling the tiles apart.
  Widget _buildQuickActionsGrid(
    BuildContext context,
    AppLocalizations l10n,
    bool isManager,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color line = isDark ? AppColors.borderDark : AppColors.borderLight;

    final items = <_QuickAction>[
      if (isManager)
        _QuickAction(
          label: l10n.managerPortal,
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF7C83FD),
          onTap: () => context.push(AppRoutes.companyAdmin),
        ),
      _QuickAction(
        label: l10n.leaves,
        icon: Icons.event_note_rounded,
        color: AppColors.secondary,
        onTap: () => context.push(AppRoutes.leaveList),
      ),
      _QuickAction(
        label: l10n.payslips,
        icon: Icons.receipt_long_rounded,
        color: AppColors.primaryAccent,
        onTap: () => context.push(AppRoutes.payslip),
      ),
      _QuickAction(
        label: l10n.overtime,
        icon: Icons.more_time_rounded,
        color: const Color(0xFF7C83FD),
        onTap: () => context.push(AppRoutes.requestOvertime),
      ),
      _QuickAction(
        label: l10n.expenses,
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.warning,
        onTap: () => context.push(AppRoutes.expense),
      ),
      if (!isManager)
        _QuickAction(
          label: l10n.holidays,
          icon: Icons.celebration_rounded,
          color: const Color(0xFFEC4899),
          onTap: () => context.push(AppRoutes.employeeHolidays),
        ),
      _QuickAction(
        label: l10n.more,
        icon: Icons.apps_rounded,
        color: AppColors.primary,
        onTap: () => _showMoreServicesSheet(context, l10n, isManager),
      ),
    ];

    const int columns = 3;
    final int rows = (items.length + columns - 1) ~/ columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, title: l10n.quickFeatures),
        const SizedBox(height: 14),
        Material(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (int r = 0; r < rows; r++) ...[
                if (r > 0) Container(height: 1, color: line),
                Row(
                  children: [
                    for (int c = 0; c < columns; c++) ...[
                      if (c > 0)
                        Container(
                          width: 1,
                          height: _kActionTileHeight,
                          color: line,
                        ),
                      Expanded(
                        child: r * columns + c < items.length
                            ? _buildActionTile(context, items[r * columns + c])
                            : const SizedBox(height: _kActionTileHeight),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, _QuickAction action) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      child: SizedBox(
        height: _kActionTileHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 25, color: action.color),
            const SizedBox(height: 9),
            SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: isDark ? AppColors.grey200 : AppColors.grey700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreServicesSheet(
    BuildContext context,
    AppLocalizations l10n,
    bool isManager,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetIconBg = isDark
        ? const Color(0xFF242424)
        : const Color(0xFFF1F5F9);
    final Color sheetIconBorder = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE2E8F0);
    final Color sheetIconColor = isDark
        ? const Color(0xFF93C5FD)
        : AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
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
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(
                      Icons.track_changes_rounded,
                      color: sheetIconColor,
                    ),
                  ),
                  title: Text(
                    l10n.myKpis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  subtitle: Text(
                    'Track performance & targets',
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
                    context.push(AppRoutes.kpi);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(Icons.school_rounded, color: sheetIconColor),
                  ),
                  title: Text(
                    l10n.training,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  subtitle: Text(
                    'Courses & skills development',
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
                    context.push(AppRoutes.training);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(Icons.gavel_rounded, color: sheetIconColor),
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
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(Icons.policy_rounded, color: sheetIconColor),
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
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(Icons.folder_rounded, color: sheetIconColor),
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
                      color: sheetIconBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sheetIconBorder, width: 1),
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      color: sheetIconColor,
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
                const SizedBox(height: 8),
              ],
            ),
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

  DateTime? _parseDateTime(String? timeStr, String? dateStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(timeStr).toLocal();
    } catch (_) {
      try {
        final parts = timeStr.trim().split(':');
        if (parts.length >= 2) {
          final now = dateStr != null
              ? (DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now())
              : DateTime.now();
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final s = parts.length > 2 ? int.parse(parts[2].split('.').first) : 0;
          return DateTime(now.year, now.month, now.day, h, m, s);
        }
      } catch (_) {}
      return null;
    }
  }

  String _formatCompletedDuration(TodayAttendance? today) {
    if (today == null) return '0s';
    if (today.clockIn != null && today.clockOut != null) {
      final inDt = _parseDateTime(today.clockIn, today.date);
      final outDt = _parseDateTime(today.clockOut, today.date);
      if (inDt != null && outDt != null) {
        final diffSeconds = outDt.difference(inDt).inSeconds;
        if (diffSeconds >= 0) {
          return formatDurationSeconds(diffSeconds);
        }
      }
    }
    if (today.workHours != null) {
      return formatDurationHoursWithSeconds(today.workHours);
    }
    return _formatTime(today.clockOut);
  }
}

class _DashboardLoadingState extends StatelessWidget {
  final String message;

  const _DashboardLoadingState({required this.message});

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
    // Matches the single connected panel the real overview renders.
    return const _SkeletonBlock(height: 210, radius: 20);
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
  final _ClockPhase phase;
  final VoidCallback onSwipe;

  const _SwipeToClockButton({
    required this.l10n,
    required this.isClockedIn,
    required this.onSwipe,
    required this.phase,
    this.isOvertime = false,
    this.isLoading = false,
  });

  @override
  State<_SwipeToClockButton> createState() => _SwipeToClockButtonState();
}

class _SwipeToClockButtonState extends State<_SwipeToClockButton>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  // Idle loop that drives the label shine, the chevron chase and the knob's
  // breathing glow. One controller for all three so the invite reads as a
  // single gesture rather than three unrelated tics.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  double _dragValue = 0.0;
  bool _triggered = false;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    // Nothing to invite once the day is over, so the ticker stays parked.
    if (widget.phase != _ClockPhase.done) _idle.repeat();
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
  void didUpdateWidget(covariant _SwipeToClockButton old) {
    super.didUpdateWidget(old);
    if (widget.phase == _ClockPhase.done) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _animateTo(
    double target, {
    VoidCallback? onComplete,
    Curve curve = Curves.easeOutCubic,
  }) {
    _animation = Tween<double>(
      begin: _dragValue,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: curve));
    _animController.reset();
    _animController.forward().then((_) {
      onComplete?.call();
    });
  }

  void _triggerSuccess(double maxDrag) {
    if (_triggered) return;
    setState(() => _triggered = true);
    HapticFeedback.mediumImpact();
    _animateTo(
      maxDrag,
      onComplete: () {
        HapticFeedback.heavyImpact();
        widget.onSwipe();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _animateTo(
              0.0,
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _triggered = false;
                    _armed = false;
                  });
                }
              },
            );
          }
        });
      },
    );
  }

  // Triangular pulse peaking at a staggered offset per chevron, so the arrows
  // light up left-to-right like a runway.
  double _chevronOpacity(double t, int index) {
    final p = (t + 1.0 - index * 0.16) % 1.0;
    return 0.22 + 0.78 * (1.0 - (p - 0.18).abs() * 4.5).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // The knob sits inside the track with a uniform inset, so nothing ever
    // pokes out of the pill and no glow has to be clipped away.
    const double height = 63.2;
    const double inset = 5.2;
    const double knob = height - inset * 2;

    // The colour is the message: green means the clock wants a swipe (early or
    // on time, in or out), amber means they are on the clock inside their
    // window, red means the day is closed. Tuned to read on the blue hero.
    final (Color color, Color iconColor) = widget.isOvertime
        ? (widget.isClockedIn
              ? (Colors.deepPurpleAccent, Colors.white)
              : (Colors.white, Colors.deepPurple))
        : switch (widget.phase) {
            _ClockPhase.working => (
              const Color(0xFFFBBF24),
              const Color(0xFF6B3F05),
            ),
            _ClockPhase.done => (
              const Color(0xFFF87171),
              const Color(0xFF6B1414),
            ),
            _ => (const Color(0xFF34D399), const Color(0xFF064B34)),
          };

    if (widget.phase == _ClockPhase.done) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(inset),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: color.withValues(alpha: 0.34), width: 1),
        ),
        child: Row(
          children: [
            // Balances the parked knob so the label stays optically centred.
            const SizedBox(width: knob),
            Expanded(
              child: Text(
                widget.l10n.shiftCompleted,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Knob parked at the finish line: the swipe already happened.
            Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(Icons.check_rounded, color: iconColor, size: 23),
            ),
          ],
        ),
      );
    }

    final text = widget.isOvertime
        ? (widget.isClockedIn
              ? widget.l10n.swipeToClockOutOT
              : widget.l10n.swipeToClockInOT)
        : (widget.isClockedIn
              ? widget.l10n.swipeToClockOut
              : widget.l10n.swipeToClockIn);

    // Amber → green at the end of the shift is a state change, not a blink:
    // fade it so the button looks like it decided, rather than glitched.
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
      builder: (context, animated, _) {
        final tint = animated ?? color;
        return LayoutBuilder(
          builder: (context, constraints) {
            final double maxDrag = (constraints.maxWidth - knob - inset * 2)
                .clamp(0.0, double.infinity);
            final double progress = maxDrag > 0
                ? (_dragValue / maxDrag).clamp(0.0, 1.0)
                : 0.0;
            final double textOpacity = (1.0 - progress * 1.8).clamp(0.0, 1.0);

            return Container(
              height: height,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: tint.withValues(alpha: _armed ? 0.60 : 0.32),
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
                  final next = (_dragValue + details.delta.dx).clamp(
                    0.0,
                    maxDrag,
                  );
                  // One crisp tick at the point of no return, so the thumb feels
                  // the button arm itself.
                  final armedNow = next > maxDrag * 0.45;
                  if (armedNow != _armed) HapticFeedback.selectionClick();
                  setState(() {
                    _dragValue = next;
                    _armed = armedNow;
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_triggered || widget.isLoading) return;
                  final velocity = details.primaryVelocity ?? 0.0;
                  // Trigger if dragged over 45% or swiped with forward velocity
                  if (_dragValue > maxDrag * 0.45 || velocity > 250) {
                    _triggerSuccess(maxDrag);
                  } else {
                    setState(() => _armed = false);
                    _animateTo(0.0);
                  }
                },
                onHorizontalDragCancel: () {
                  if (!_triggered && !widget.isLoading) {
                    setState(() => _armed = false);
                    _animateTo(0.0);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Trail that fills in behind the knob and brightens once armed.
                      if (_dragValue > 0)
                        Container(
                          width: _dragValue + knob + inset * 2,
                          height: height,
                          color: tint.withValues(alpha: _armed ? 0.32 : 0.18),
                        ),

                      // Label: a shine sweeps through it and three chevrons chase
                      // toward the finish line.
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
                                child: AnimatedBuilder(
                                  animation: _idle,
                                  builder: (context, _) {
                                    final c = _idle.value;
                                    final shine = -0.3 + 1.6 * c;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ShaderMask(
                                          blendMode: BlendMode.srcIn,
                                          shaderCallback: (rect) =>
                                              LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.75,
                                                  ),
                                                  Colors.white,
                                                  Colors.white.withValues(
                                                    alpha: 0.75,
                                                  ),
                                                ],
                                                stops: [
                                                  (shine - 0.3).clamp(0.0, 1.0),
                                                  shine.clamp(0.0, 1.0),
                                                  (shine + 0.3).clamp(0.0, 1.0),
                                                ],
                                              ).createShader(rect),
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        for (int i = 0; i < 3; i++)
                                          Opacity(
                                            opacity: _chevronOpacity(c, i),
                                            child: const Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),

                      // Draggable knob, inset from the track on every side.
                      Positioned(
                        left: inset + _dragValue,
                        child: Material(
                          color: tint,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.35),
                          child: InkWell(
                            onTap: widget.isLoading || _triggered
                                ? null
                                : () => _triggerSuccess(maxDrag),
                            child: SizedBox(
                              width: knob,
                              height: knob,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(
                                      scale: anim,
                                      child: FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                    ),
                                child: Icon(
                                  _triggered
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  key: ValueKey(_triggered),
                                  color: iconColor,
                                  size: 23,
                                ),
                              ),
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
        );
      },
    );
  }
}

class _PulsingStatusDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingStatusDot({required this.color, this.size = 6.0});

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.8),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RealtimeActiveDurationBadge extends StatefulWidget {
  final DateTime? clockInTime;
  final num? fallbackWorkHours;
  final Color accent;
  final String activeDurationLabel;

  const _RealtimeActiveDurationBadge({
    required this.clockInTime,
    required this.fallbackWorkHours,
    required this.accent,
    required this.activeDurationLabel,
  });

  @override
  State<_RealtimeActiveDurationBadge> createState() =>
      _RealtimeActiveDurationBadgeState();
}

class _RealtimeActiveDurationBadgeState
    extends State<_RealtimeActiveDurationBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (widget.clockInTime != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant _RealtimeActiveDurationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clockInTime != widget.clockInTime) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatLiveDuration() {
    if (widget.clockInTime != null) {
      final elapsedSeconds =
          DateTime.now().difference(widget.clockInTime!).inSeconds;
      final safeSeconds = elapsedSeconds > 0 ? elapsedSeconds : 0;
      return '${widget.activeDurationLabel}${_formatHMS(safeSeconds)}';
    }
    if (widget.fallbackWorkHours != null) {
      final totalSeconds = (widget.fallbackWorkHours!.abs() * 3600).round();
      return '${widget.activeDurationLabel}${_formatHMS(totalSeconds)}';
    }
    return '';
  }

  String _formatHMS(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatLiveDuration();
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: widget.accent,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
