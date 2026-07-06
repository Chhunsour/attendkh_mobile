import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/app.dart';
import 'package:mpg_hr_mobile_app/utils/storage/secure_storage.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await SecureStorageService.instance.init();
  DioClient.init();
  AppLogger.init();
  
  // Initialize FCM (non-blocking)
  FcmService.instance.init();

  runApp(
    const ProviderScope(
      child: MPGHRApp(),
    ),
  );
}