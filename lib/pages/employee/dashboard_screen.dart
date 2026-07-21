import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/providers/dashboard_provider.dart';
import 'package:mpg_hr_mobile_app/pages/employee/clock_in_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isClocking = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool isPhysicalDevice = true;
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          isPhysicalDevice = androidInfo.isPhysicalDevice;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          isPhysicalDevice = iosInfo.isPhysicalDevice;
        }
      } catch (_) {}

      if (!isPhysicalDevice) {
        if (mounted) {
          setState(() {
            _currentPosition = Position(
              longitude: 104.9282,
              latitude: 11.5564, 
              timestamp: DateTime.now(),
              accuracy: 10,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });
        }
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // ignore: deprecated_member_use
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = pos);

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        if (mounted) setState(() => _currentPosition = position);
      });
    } catch (e) {
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

  Future<void> _handleSimpleClockOut({bool isOvertime = false}) async {
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
              Text(isOvertime ? 'Confirm Overtime Clock Out' : 'Confirm Clock Out', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
              const SizedBox(height: 12),
              Text(
                isOvertime ? 'Are you sure you want to end your overtime?' : 'Are you sure you want to clock out for the day? Your work hours will be recorded.', 
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
                      child: const Text('Cancel', style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.bold)),
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
                      child: const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          SnackBar(content: Text(isOvertime ? '👋 Overtime ended!' : '👋 Clocked out successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isClocking = false);
      String msg = 'Clock-out failed';
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

  Widget _buildClockButton(BuildContext context, WidgetRef ref, bool isClockedIn, ProfileData? profile, TodayAttendance? today) {
    final bool isRegularCompleted = today?.clockIn != null && today?.clockOut != null;
    final bool isOvertimeIn = today?.overtimeIn != null && today?.overtimeOut == null;
    final bool isOvertimeCompleted = today?.overtimeIn != null && today?.overtimeOut != null;

    if (isOvertimeCompleted) {
      return const SizedBox(); // Should not show any button
    }

    final isClockingOut = isClockedIn || isOvertimeIn;
    final isOvertimeAction = isRegularCompleted && !isOvertimeCompleted;

    return _SwipeToClockButton(
      isClockedIn: isClockingOut,
      isOvertime: isOvertimeAction,
      isLoading: _isClocking,
      onSwipe: () {
        if (_isClocking) return;

        // If clocking out, skip geofence and photo
        if (isClockingOut) {
          _handleSimpleClockOut(isOvertime: isOvertimeAction);
          return;
        }

        // If clocking in, enforce location and new selfie screen
        if (_currentPosition == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Waiting for location data...')));
          return;
        }

        final args = ClockInArgs(
          isClockIn: true,
          isOvertime: isOvertimeAction,
          branchName: profile?.branchName ?? 'Unknown Location',
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
    final todayAsync = ref.watch(todayAttendanceProvider);
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final summaryAsync = ref.watch(employeeDashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${authState.userName ?? 'User'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
            ),
            Text(
              authState.companyName ?? 'My Company',
              style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.grey700),
            onPressed: () => context.push(AppRoutes.notifications),
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
                      ? NetworkImage(profileAsync.value!.photoUrl!)
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
              _buildClockCard(context, ref, today, profileAsync: profileAsync),
              
              summaryAsync.maybeWhen(
                data: (summary) => _buildLateWarningBanner(summary),
                orElse: () => const SizedBox(),
              ),
              
              const SizedBox(height: 28),

              const Text(
                'Quick Features',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800),
              ),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(context, authState.isBranchManager),

              const SizedBox(height: 28),
              
              summaryAsync.when(
                data: (summary) => _buildSummarySection(context, summary),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => const SizedBox(),
              ),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(message: 'Loading dashboard...'),
        error: (error, _) => _buildError(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildLateWarningBanner(Map<String, dynamic> summary) {
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
                const Text('Late Attendance Warning', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Notice: You have been late $lateCount times this month. Please ensure you clock in on time to adhere to company policy.',
                  style: const TextStyle(color: AppColors.grey800, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, Map<String, dynamic> summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800),
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
              title: 'Upcoming Leaves',
              count: (summary['upcoming_leaves'] as List?)?.length.toString() ?? '0',
              icon: Icons.event_available,
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.leaveList),
            ),
            _buildSummaryCard(
              title: 'Recent Activity',
              count: (summary['recent_attendance'] as List?)?.length.toString() ?? '0',
              icon: Icons.how_to_reg,
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.attendance),
            ),
            _buildSummaryCard(
              title: 'Active Trainings',
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

  Widget _buildClockCard(BuildContext context, WidgetRef ref, TodayAttendance? today, {required AsyncValue<ProfileData> profileAsync}) {
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
            Text('Overtime started at ${_formatTime(today!.overtimeIn!)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          ] else if (isOvertimeCompleted) ...[
            const Text('Overtime Completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ] else if (isClockedIn) ...[
            Text('Clocked in at ${_formatTime(today!.clockIn!)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            if (today.workHours != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                child: Text('Active duration: ${today.workHours!.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ] else if (isCompleted) ...[
            const Text('Shift Completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            if (today!.workHours != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                child: Text('Worked: ${today.workHours!.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ] else ...[
            const Text('Ready to Work?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
          const SizedBox(height: 24),

          if (!isOvertimeCompleted)
            profileAsync.maybeWhen(
              data: (profile) {
                if (profile.branchLat == null || profile.branchLng == null || profile.branchRadius == null) {
                  return _buildClockButton(context, ref, isClockedIn, profile, today);
                }
                
                final distance = _calculateDistance(profile);
                if (distance == null) {
                   return const Padding(
                     padding: EdgeInsets.only(top: 8),
                     child: Text('Calculating location...', style: TextStyle(color: Colors.white70)),
                   );
                }

                if (isClockedIn || isOvertimeIn || distance <= profile.branchRadius!) {
                  return Column(
                    children: [
                      if (!isClockedIn && !isOvertimeIn && !isCompleted)
                        Text('Within radius (${distance.toStringAsFixed(0)}m / ${profile.branchRadius}m)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      if (isClockedIn || isOvertimeIn)
                        const Text('You can clock out from anywhere.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      _buildClockButton(context, ref, isClockedIn, profile, today),
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
                        Text('You are ${distance.toStringAsFixed(0)}m away.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Must be within ${profile.branchRadius}m to clock in.', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
              },
              orElse: () => _buildClockButton(context, ref, isClockedIn, null, today),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isBranchManager) {
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
            title: 'Manager Portal',
            description: 'Team approvals',
            icon: Icons.admin_panel_settings_outlined,
            color: Colors.deepPurple,
            onTap: () => context.push(AppRoutes.companyAdmin),
          ),
        _GridItem(
          title: 'Leaves',
          description: 'Request off days',
          icon: Icons.event_note_outlined,
          color: AppColors.secondary,
          onTap: () => context.push(AppRoutes.leaveList),
        ),
        _GridItem(
          title: 'Expenses',
          description: 'Claim reimbursements',
          icon: Icons.receipt_long_outlined,
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.expense),
        ),
        _GridItem(
          title: 'Payslips',
          description: 'View monthly statements',
          icon: Icons.monetization_on_outlined,
          color: AppColors.success,
          onTap: () => context.push(AppRoutes.payslip),
        ),
        _GridItem(
          title: 'History',
          description: 'Check attendance logs',
          icon: Icons.history_toggle_off_outlined,
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.attendance),
        ),
        _GridItem(
          title: 'Training',
          description: 'Enroll in courses',
          icon: Icons.school_outlined,
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.training),
        ),
        _GridItem(
          title: 'Holidays',
          description: 'Company calendar',
          icon: Icons.celebration_outlined,
          color: const Color(0xFFEAB308), // Yellow/Gold
          onTap: () => context.push(AppRoutes.employeeHolidays),
        ),
        _GridItem(
          title: 'Rules',
          description: 'Company policies',
          icon: Icons.shield_outlined,
          color: Colors.teal,
          onTap: () => context.push(AppRoutes.companyRules),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            const Text('Failed to load dashboard', style: TextStyle(color: AppColors.grey600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(todayAttendanceProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
  final bool isClockedIn;
  final bool isOvertime;
  final bool isLoading;
  final VoidCallback onSwipe;

  const _SwipeToClockButton({required this.isClockedIn, required this.onSwipe, this.isOvertime = false, this.isLoading = false});

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
        ? (widget.isClockedIn ? 'Swipe to Clock Out (OT)' : 'Swipe to Clock In (OT)')
        : (widget.isClockedIn ? 'Swipe to Clock Out' : 'Swipe to Clock In');

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
