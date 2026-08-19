import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/app.dart';
import 'package:mpg_hr_mobile_app/utils/storage/secure_storage.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await SecureStorageService.instance.init();
  DioClient.init();
  AppLogger.init();

  // Handle Flutter framework errors gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e('FlutterError caught', details.exception, details.stack);
  };

  // Custom ErrorWidget fallback to prevent red error screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final isTimeout = details.exception is TimeoutException ||
        details.exception.toString().toLowerCase().contains('timed out') ||
        details.exception.toString().toLowerCase().contains('connection');

    return Material(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isTimeout ? Colors.amber : Colors.redAccent)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTimeout
                          ? Icons.wifi_off_rounded
                          : Icons.error_outline_rounded,
                      color: isTimeout ? Colors.amber : Colors.redAccent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTimeout ? 'Connection Issue' : 'Something went wrong',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTimeout
                        ? 'Unable to connect to the server. Please check your internet connection and try again.'
                        : (details.exception is AppException
                            ? (details.exception as AppException).message
                            : 'An unexpected issue occurred. Please try again.'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Trigger retry
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: MPGHRApp(),
    ),
  );
}