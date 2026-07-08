import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/attendance_repository.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAttendanceProvider);
    final authState = ref.watch(authProvider);

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
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 1.5),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
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
              _buildClockCard(context, ref, today),
              const SizedBox(height: 28),

              const Text(
                'Quick Features',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800),
              ),
              const SizedBox(height: 16),

              _buildQuickActionsGrid(context),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(message: 'Loading dashboard...'),
        error: (error, _) => _buildError(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildClockCard(BuildContext context, WidgetRef ref, TodayAttendance? today) {
    final isClockedIn = today?.clockIn != null && today?.clockOut == null;
    final isCompleted = today?.clockIn != null && today?.clockOut != null;

    final Color cardColor = isClockedIn
        ? AppColors.success
        : (isCompleted ? AppColors.grey800 : AppColors.primary);

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
              isClockedIn
                  ? Icons.timer_outlined
                  : (isCompleted ? Icons.check_circle : Icons.access_time_rounded),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            today?.date ?? DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
            style: const TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          if (isClockedIn) ...[
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

          if (!isCompleted)
            _SwipeToClockButton(
              isClockedIn: isClockedIn,
              onSwipe: () {
                if (isClockedIn) {
                  _handleClockOut(context, ref);
                } else {
                  _handleClockIn(context, ref);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
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

  Future<void> _handleClockIn(BuildContext context, WidgetRef ref) async {
    final Map<String, dynamic>? attendanceData = await _captureAttendanceData(context);
    if (attendanceData == null) return;

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockIn(
        lat: attendanceData['latitude'] as double,
        lng: attendanceData['longitude'] as double,
        photoPath: attendanceData['photo_path'] as String,
      );
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Clocked in successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      String msg = 'Clock-in failed';
      if (e is AppException) {
        msg = e.message;
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _handleClockOut(BuildContext context, WidgetRef ref) async {
    final Map<String, dynamic>? attendanceData = await _captureAttendanceData(context);
    if (attendanceData == null) return;

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.clockOut(
        lat: attendanceData['latitude'] as double,
        lng: attendanceData['longitude'] as double,
        photoPath: attendanceData['photo_path'] as String,
      );
      ref.invalidate(todayAttendanceProvider);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('👋 Clocked out successfully!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      String msg = 'Clock-out failed';
      if (e is AppException) {
        msg = e.message;
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $msg'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<Map<String, dynamic>?> _captureAttendanceData(BuildContext context) async {
    final deviceInfo = DeviceInfoPlugin();
    bool isPhysicalDevice = true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }

    double latitude = 0.0;
    double longitude = 0.0;
    String photoPath = '';

    // Location
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // ignore: deprecated_member_use
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Location Warning: ${e.toString()}. Using mock location.'), backgroundColor: AppColors.warning));
      latitude = 11.5564;
      longitude = 104.9282;
    }

    // Selfie Image
    if (!isPhysicalDevice) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/dummy_selfie.jpg');
        await file.writeAsBytes(List<int>.filled(100, 0));
        photoPath = file.path;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 Simulator: generated mock selfie photo'), backgroundColor: AppColors.info, duration: Duration(seconds: 2)));
      } catch (e) {
        photoPath = '';
      }
    } else {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Camera permission is required for selfie verification.'), backgroundColor: AppColors.danger));
        return null;
      }

      final picker = ImagePicker();
      try {
        final photo = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front, maxWidth: 600);
        if (photo == null) return null;
        photoPath = photo.path;
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Camera exception: ${e.toString()}. Generating simulator fallback.'), backgroundColor: AppColors.warning));
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/dummy_selfie.jpg');
          await file.writeAsBytes(List<int>.filled(100, 0));
          photoPath = file.path;
        } catch (_) {
          return null;
        }
      }
    }

    return {'latitude': latitude, 'longitude': longitude, 'photo_path': photoPath};
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
  final VoidCallback onSwipe;

  const _SwipeToClockButton({required this.isClockedIn, required this.onSwipe});

  @override
  State<_SwipeToClockButton> createState() => _SwipeToClockButtonState();
}

class _SwipeToClockButtonState extends State<_SwipeToClockButton> {
  double _dragValue = 0.0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    const double height = 56.0;
    final color = widget.isClockedIn ? AppColors.warning : Colors.white;
    final textColor = widget.isClockedIn ? AppColors.warning : AppColors.primary;
    final text = widget.isClockedIn ? 'Swipe to Clock Out' : 'Swipe to Clock In';

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
                child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_triggered) return;
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
                    child: Icon(Icons.double_arrow_rounded, color: textColor, size: 20),
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
