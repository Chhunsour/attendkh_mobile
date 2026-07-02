import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/app.dart';
import 'package:mpg_hr_mobile_app/core/storage/secure_storage.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/core/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await SecureStorageService.instance.init();
  DioClient.init();
  AppLogger.init();

  runApp(
    const ProviderScope(
      child: MPGHRApp(),
    ),
  );
}