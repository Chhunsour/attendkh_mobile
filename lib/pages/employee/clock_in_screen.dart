import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_marketing_names/device_marketing_names.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/providers/attendance_provider.dart';
import 'package:attendkh/services/network/exceptions.dart';
import 'package:attendkh/utils/image_compressor.dart';
import 'package:attendkh/providers/notifications_provider.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class ClockInArgs {
  final bool isClockIn;
  final bool isOvertime;
  final String branchName;
  final double latitude;
  final double longitude;
  final double distance;

  /// False when the branch has no coordinates configured, i.e. there is no
  /// geofence to validate against. It is never false merely because GPS was
  /// unavailable — the dashboard refuses to start a clock action in that case.
  final bool hasGeofence;
  final int? radius;
  final bool isLateNow;
  final bool isEarlyLeaveNow;
  final String? earlyLeaveReason;

  ClockInArgs({
    required this.isClockIn,
    this.isOvertime = false,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.hasGeofence = true,
    this.radius,
    this.isLateNow = false,
    this.isEarlyLeaveNow = false,
    this.earlyLeaveReason,
  });
}

class ClockInScreen extends ConsumerStatefulWidget {
  final ClockInArgs args;

  const ClockInScreen({super.key, required this.args});

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen>
    with SingleTickerProviderStateMixin {
  String? _photoPath;
  bool _isSubmitting = false;
  final TextEditingController _lateReasonController = TextEditingController();
  int? _selectedReasonIndex;

  // Held as a field so rebuilds (chip taps, typing) reuse one ticker instead
  // of restarting the clock.
  final Stream<DateTime> _clock = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  // Slow sweep of the capture reticle while it waits for a shot.
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  static const List<Map<String, String>> _cambodiaLateReasons = [
    {
      'icon': '🚗',
      'en': 'Heavy Traffic',
      'km': 'ស្ទះចរាចរណ៍ (Traffic)',
    },
    {
      'icon': '🌧️',
      'en': 'Heavy Rain',
      'km': 'ភ្លៀងធ្លាក់ខ្លាំង (Heavy Rain)',
    },
    {
      'icon': '🛵',
      'en': 'Vehicle Issue',
      'km': 'យានជំនិះមានបញ្ហា (Vehicle)',
    },
    {
      'icon': '🏥',
      'en': 'Medical Clinic',
      'km': 'ពិនិត្យសុខភាព (Medical)',
    },
    {
      'icon': '👨‍👩‍👧',
      'en': 'Family Emergency',
      'km': 'ការងារគ្រួសារបន្ទាន់ (Emergency)',
    },
    {
      'icon': '✏️',
      'en': 'Other (Custom)',
      'km': 'មូលហេតុផ្សេងទៀត (Other)',
    },
  ];

  @override
  void dispose() {
    _scan.dispose();
    _lateReasonController.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    final l10n = AppLocalizations.of(context)!;
    final deviceInfo = DeviceInfoPlugin();
    bool isPhysicalDevice = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }

    if (!isPhysicalDevice) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/dummy_selfie.png');
        final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');
        await file.writeAsBytes(bytes);
        setState(() {
          _photoPath = file.path;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.simMockSelfie), backgroundColor: AppColors.info, duration: const Duration(seconds: 2)));
        }
      } catch (e) {
        // Handle error
      }
      return;
    }

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cameraPermissionRequired), backgroundColor: AppColors.danger));
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, maxWidth: 600);
      if (photo != null) {
        final compressed = await ImageCompressor.compressToWebp(photo.path);
        setState(() {
          _photoPath = compressed.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cameraException + e.toString()), backgroundColor: AppColors.warning));
      }
    }
  }

  String _mapIosMachineToName(String machine) {
    const map = {
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,4': 'iPhone 13 Mini',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,6': 'iPhone SE (3rd Gen)',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
      'iPhone18,1': 'iPhone 17 Pro',
      'iPhone18,2': 'iPhone 17 Pro Max',
      'iPhone18,3': 'iPhone 17',
      'iPhone18,4': 'iPhone 17 Plus',
    };
    return map[machine] ?? machine;
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand.isNotEmpty 
            ? androidInfo.brand[0].toUpperCase() + androidInfo.brand.substring(1) 
            : 'Android';
        final model = androidInfo.model;
        try {
          final deviceNames = DeviceMarketingNames();
          final String marketingName = await deviceNames.getSingleName();
          if (marketingName.isNotEmpty) {
            return '$brand $marketingName'.trim();
          }
        } catch (_) {}
        return '$brand $model'.trim();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final machine = iosInfo.utsname.machine;
        return _mapIosMachineToName(machine);
      }
    } catch (e) {
      // Ignore fallback
    }
    return 'app';
  }

  Future<void> _submitClockIn() async {
    if (_photoPath == null) return;
    
    final l10n = AppLocalizations.of(context)!;
    final radius = widget.args.radius ?? 500; // default 500m
    final bool isGeoValid =
        !widget.args.hasGeofence || widget.args.distance <= radius;

    if (!isGeoValid) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.outOfRange),
          content: Text(l10n.outOfRangeDesc1 + widget.args.distance.toStringAsFixed(0) + l10n.outOfRangeDesc2 + radius.toString() + l10n.outOfRangeDesc3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: Text(l10n.clockInAnyway, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final String deviceName = await _getDeviceName();

      if (widget.args.isLateNow && _lateReasonController.text.trim().isEmpty) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.fieldRequired), backgroundColor: AppColors.danger),
          );
        }
        return;
      }

      if (widget.args.isClockIn) {
        if (widget.args.isOvertime) {
          await repo.overtimeIn(
            lat: widget.args.latitude,
            lng: widget.args.longitude,
            deviceId: deviceName,
            isGeoValid: isGeoValid,
          );
        } else {
          await repo.clockIn(
            lat: widget.args.latitude,
            lng: widget.args.longitude,
            photoPath: _photoPath!,
            deviceId: deviceName,
            isGeoValid: isGeoValid,
            lateReason: _lateReasonController.text.trim(),
          );
        }
      } else {
        if (widget.args.isOvertime) {
          await repo.overtimeOut(
            lat: widget.args.latitude,
            lng: widget.args.longitude,
            deviceId: deviceName,
            isGeoValid: isGeoValid,
          );
        } else {
          await repo.clockOut(
            lat: widget.args.latitude,
            lng: widget.args.longitude,
            photoPath: _photoPath!,
            deviceId: deviceName,
            isGeoValid: isGeoValid,
            earlyLeaveReason: widget.args.earlyLeaveReason ??
                (_lateReasonController.text.trim().isNotEmpty
                    ? _lateReasonController.text.trim()
                    : null),
          );
        }
      }
      
      ref.invalidate(todayAttendanceProvider);
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.args.isClockIn ? l10n.clockedInSuccessfullyEmoji : l10n.clockedOutSuccessfullyEmoji), 
            backgroundColor: AppColors.success, 
            behavior: SnackBarBehavior.floating
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String msg = widget.args.isClockIn ? l10n.clockInFailed : l10n.clockOutFailed;
        if (e is AppException) {
          msg = e.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKhmer = Localizations.localeOf(context).languageCode == 'km';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = widget.args;
    final title = args.isClockIn
        ? (args.isOvertime ? l10n.overtimeCheckIn : l10n.checkInTitle)
        : (args.isOvertime ? l10n.overtimeCheckOut : l10n.checkOutTitle);

    final radius = args.radius ?? 500;
    final inRange = !args.hasGeofence || args.distance <= radius;
    final needsReason = args.isClockIn && !args.isOvertime && args.isLateNow;
    final hasReason = _lateReasonController.text.trim().isNotEmpty;
    final hasPhoto = _photoPath != null;
    final ready = hasPhoto && (!needsReason || hasReason);

    // The confirm button used to just sit there greyed out. Now it says what
    // is still missing.
    final String? blocker = hasPhoto
        ? (needsReason && !hasReason
              ? (isKhmer
                    ? 'សូមបញ្ជាក់មូលហេតុមកយឺត'
                    : 'Add a reason for being late')
              : null)
        : (isKhmer ? 'ថតរូបសែលហ្វីជាមុនសិន' : 'Take a selfie to continue');

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            _buildHeader(context, l10n, isDark, title, isKhmer),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stepRow(
                      context,
                      index: 1,
                      done: hasPhoto,
                      title: l10n.takeSelfie,
                      subtitle: l10n.takeSelfieToVerify,
                      status: hasPhoto
                          ? _StepStatus.done
                          : _StepStatus.pending,
                      statusLabel: hasPhoto
                          ? (isKhmer ? 'បានផ្ទៀងផ្ទាត់' : 'Verified')
                          : (isKhmer ? 'រង់ចាំ' : 'Required'),
                      child: _buildSelfieStep(context, l10n, isDark, isKhmer),
                    ),

                    if (needsReason)
                      _stepRow(
                        context,
                        index: 2,
                        done: hasReason,
                        title: isKhmer
                            ? 'មូលហេតុមកយឺត'
                            : 'Reason for being late',
                        subtitle: isKhmer
                            ? 'ជ្រើសរើសមួយ ឬសរសេរដោយខ្លួនឯង'
                            : 'Pick one, or write your own',
                        status: hasReason
                            ? _StepStatus.done
                            : _StepStatus.warning,
                        statusLabel: hasReason
                            ? (isKhmer ? 'បានបំពេញ' : 'Provided')
                            : (isKhmer ? 'ចាំបាច់' : 'Required'),
                        child: _buildReasonStep(context, isDark, isKhmer),
                      ),

                    _stepRow(
                      context,
                      index: needsReason ? 3 : 2,
                      done: inRange,
                      isLast: true,
                      title: isKhmer ? 'ទីតាំង' : 'Location',
                      subtitle: args.branchName,
                      status: inRange ? _StepStatus.done : _StepStatus.warning,
                      statusLabel: inRange
                          ? (isKhmer ? 'ក្នុងតំបន់' : 'In range')
                          : (isKhmer ? 'ក្រៅតំបន់' : 'Out of range'),
                      child: _buildLocationStep(
                        context,
                        isDark,
                        isKhmer,
                        radius,
                        inRange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(context, l10n, isDark, title, ready, blocker),
          ],
        ),
      ),
    );
  }

  // ── Header: same gradient slab as the dashboard, with a running clock so
  // the moment being stamped is visible while you fill the form. ──
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    String title,
    bool isKhmer,
  ) {
    final baseColor = isDark
        ? const Color(0xFF0A2472)
        : const Color(0xFF0B2A80);
    final args = widget.args;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
              16,
              MediaQuery.paddingOf(context).top + 6,
              16,
              22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (args.isOvertime)
                      _headerBadge('OT', const Color(0xFFC4B5FD))
                    else if (args.isLateNow)
                      _headerBadge(
                        isKhmer ? 'យឺត' : 'LATE',
                        const Color(0xFFFBBF24),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                // The stamp you are about to submit, ticking in real time.
                StreamBuilder<DateTime>(
                  stream: _clock,
                  initialData: DateTime.now(),
                  builder: (context, snap) {
                    final now = snap.data ?? DateTime.now();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          DateFormat('h:mm').format(now),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -1.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            DateFormat(':ss a').format(now),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            DateFormat('EEE, dd MMM').format(now),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── The numbered rail. Each requirement is a node; the connector makes the
  // three of them read as one sequence instead of three loose cards. ──
  Widget _stepRow(
    BuildContext context, {
    required int index,
    required bool done,
    required String title,
    required String subtitle,
    required _StepStatus status,
    required String statusLabel,
    required Widget child,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nodeColor = done ? AppColors.success : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.success
                        : nodeColor.withValues(alpha: isDark ? 0.18 : 0.10),
                    border: Border.all(
                      color: done
                          ? AppColors.success
                          : nodeColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 17,
                            color: Colors.white,
                          )
                        : Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: nodeColor,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.grey200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(status, statusLabel, isDark),
                    ],
                  ),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(_StepStatus status, String label, bool isDark) {
    final color = switch (status) {
      _StepStatus.done => AppColors.success,
      _StepStatus.warning => AppColors.warning,
      _StepStatus.pending => isDark ? AppColors.grey400 : AppColors.grey500,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── Step 1: the capture target. Empty, it is a slowly rotating scanner
  // reticle; filled, the reticle locks into a solid ring with a check. ──
  Widget _buildSelfieStep(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isKhmer,
  ) {
    final hasPhoto = _photoPath != null;
    const size = 172.0;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _takeSelfie,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Reticle: spins while it waits for a face, locks on capture.
                  SizedBox.expand(
                    child: hasPhoto
                        ? const CustomPaint(
                            painter: _ReticlePainter(
                              color: AppColors.success,
                              sweep: 84,
                            ),
                          )
                        : RotationTransition(
                            turns: _scan,
                            child: const CustomPaint(
                              painter: _ReticlePainter(
                                color: AppColors.primary,
                                sweep: 52,
                              ),
                            ),
                          ),
                  ),
                  Container(
                    width: size - 26,
                    height: size - 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.surfaceDarkElevated
                          : AppColors.grey100,
                      image: hasPhoto
                          ? DecorationImage(
                              image: FileImage(File(_photoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 44,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.tapToCapture,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (hasPhoto)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.bg(context),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (hasPhoto)
            TextButton.icon(
              onPressed: _takeSelfie,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(isKhmer ? 'ថតម្តងទៀត' : 'Retake'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 2: reason chips. The emoji sits in its own tinted tile so the row
  // has a consistent rhythm whatever the label length. ──
  Widget _buildReasonStep(BuildContext context, bool isDark, bool isKhmer) {
    final selected = _selectedReasonIndex != null
        ? _cambodiaLateReasons[_selectedReasonIndex!]
        : null;
    final isOther = selected?['en'] == 'Other (Custom)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _selectedReasonIndex,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          dropdownColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          elevation: 3,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          hint: Text(
            isKhmer ? 'ជ្រើសរើសមូលហេតុ' : 'Choose a reason',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: selected != null
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          // The closed field keeps the emoji tile; the open menu reuses it so
          // the row you tapped is the row you get.
          selectedItemBuilder: (context) => List.generate(
            _cambodiaLateReasons.length,
            (i) => _reasonRow(context, i, isDark, isKhmer, compact: true),
          ),
          items: List.generate(
            _cambodiaLateReasons.length,
            (i) => DropdownMenuItem<int>(
              value: i,
              child: _reasonRow(context, i, isDark, isKhmer),
            ),
          ),
          onChanged: (i) {
            if (i == null) return;
            setState(() {
              _selectedReasonIndex = i;
              if (_cambodiaLateReasons[i]['en'] == 'Other (Custom)') {
                _lateReasonController.clear();
              } else {
                _lateReasonController.text = isKhmer
                    ? _cambodiaLateReasons[i]['km']!
                    : _cambodiaLateReasons[i]['en']!;
              }
            });
          },
        ),

        // The free-text box is only worth the space once a reason is chosen,
        // and it is the whole point of picking "Other".
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: selected == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _lateReasonController,
                    maxLines: 2,
                    minLines: 2,
                    autofocus: isOther,
                    textCapitalization: TextCapitalization.sentences,
                    // The footer hint and the step badge both key off this text.
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      hintText: isKhmer
                          ? 'ព័ត៌មានបន្ថែម (ស្រេចចិត្ត)'
                          : 'Add detail — e.g. traffic on Monivong, left at 7:30',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.border(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.border(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _reasonRow(
    BuildContext context,
    int index,
    bool isDark,
    bool isKhmer, {
    bool compact = false,
  }) {
    final item = _cambodiaLateReasons[index];
    final isSelected = _selectedReasonIndex == index;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.12)
                : (isDark ? AppColors.surfaceDarkElevated : AppColors.grey100),
          ),
          child: Text(item['icon']!, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isKhmer ? item['km']! : item['en']!,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected && !compact)
          const Icon(Icons.check_rounded, size: 17, color: AppColors.primary),
      ],
    );
  }

  // ── Step 3: the geofence, as a distance meter. The old card said "within
  // 50m radius" without ever saying how far away you actually are. ──
  Widget _buildLocationStep(
    BuildContext context,
    bool isDark,
    bool isKhmer,
    int radius,
    bool inRange,
  ) {
    final distance = widget.args.distance;
    final ratio = !widget.args.hasGeofence
        ? 0.0
        : (radius > 0 ? (distance / radius).clamp(0.0, 1.0) : 1.0);
    final color = inRange ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  inRange
                      ? Icons.location_on_rounded
                      : Icons.wrong_location_rounded,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.args.branchName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !widget.args.hasGeofence
                          ? (isKhmer
                                ? 'មិនបានកំណត់តំបន់ការងារ'
                                : 'No work-site radius configured')
                          : isKhmer
                          ? 'ចម្ងាយ ${distance.toStringAsFixed(0)} ម៉ែត្រ · កំណត់ $radius ម៉ែត្រ'
                          : '${distance.toStringAsFixed(0)} m away · limit $radius m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: isDark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.grey100,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer: pinned so the CTA never scrolls away, and it names the thing
  // still standing between you and clocking in. ──
  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    String title,
    bool ready,
    String? blocker,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (blocker != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        blocker,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (ready && !_isSubmitting) ? _submitClockIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: isDark
                        ? AppColors.surfaceDarkElevated
                        : AppColors.grey200,
                    disabledForegroundColor: isDark
                        ? AppColors.grey500
                        : AppColors.grey400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: ready ? 2 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.confirmAction + title,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (ready) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 19),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { done, warning, pending }

/// Four arc segments with gaps between them — a camera focus reticle. Spinning
/// while empty reads as "looking for you"; a wider sweep in green reads as a
/// closed, locked ring once the shot is taken.
class _ReticlePainter extends CustomPainter {
  final Color color;

  /// Degrees covered by each of the four arcs.
  final double sweep;

  const _ReticlePainter({required this.color, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(1.5);
    const rad = math.pi / 180;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(rect, (i * 90 - sweep / 2) * rad, sweep * rad, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ReticlePainter old) =>
      old.color != color || old.sweep != sweep;
}
