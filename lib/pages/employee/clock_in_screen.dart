import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_marketing_names/device_marketing_names.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/attendance_provider.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/providers/notifications_provider.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class ClockInArgs {
  final bool isClockIn;
  final bool isOvertime;
  final String branchName;
  final double latitude;
  final double longitude;
  final double distance;
  final int? radius;

  ClockInArgs({
    required this.isClockIn,
    this.isOvertime = false,
    required this.branchName,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.radius,
  });
}

class ClockInScreen extends ConsumerStatefulWidget {
  final ClockInArgs args;

  const ClockInScreen({super.key, required this.args});

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen> {
  String? _photoPath;
  bool _isSubmitting = false;
  final TextEditingController _lateReasonController = TextEditingController();

  @override
  void dispose() {
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
    final bool isGeoValid = widget.args.distance <= radius;

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
    final title = widget.args.isClockIn 
        ? (widget.args.isOvertime ? l10n.overtimeCheckIn : l10n.checkInTitle) 
        : (widget.args.isOvertime ? l10n.overtimeCheckOut : l10n.checkOutTitle);
    
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.grey900),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.takeSelfie,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey800),
              ),
              const SizedBox(height: 32),
              
              // Camera Circle
              GestureDetector(
                onTap: _takeSelfie,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey100,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: _photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoPath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(l10n.tapToCapture, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                l10n.takeSelfieToVerify,
                style: const TextStyle(fontSize: 14, color: AppColors.grey600),
              ),
              
              const Spacer(),
              
              if (widget.args.isClockIn && !widget.args.isOvertime) ...[
                TextField(
                  controller: _lateReasonController,
                  decoration: InputDecoration(
                    labelText: 'Late Reason / Notes (Optional)',
                    hintText: 'e.g. Traffic jam, doctor appointment',
                    prefixIcon: const Icon(Icons.edit_note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Location Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.locationLabel + widget.args.branchName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey800, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.args.radius != null)
                      Text(
                        l10n.withinRadiusLabel + widget.args.radius.toString() + l10n.mRadius,
                        style: const TextStyle(color: AppColors.grey600, fontSize: 14),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_photoPath != null && !_isSubmitting) ? _submitClockIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(l10n.confirmAction + title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
