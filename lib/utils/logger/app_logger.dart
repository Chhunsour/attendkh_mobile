import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _instance = Logger(
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      // ignore: deprecated_member_use
      printTime: true,
    ),
  );

  static void init() {
    if (kDebugMode) {
      _instance.d('AppLogger initialized');
    }
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _instance.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _instance.i(message, error: error, stackTrace: stackTrace);
    }
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _instance.w(message, error: error, stackTrace: stackTrace);
    }
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance.e(message, error: error, stackTrace: stackTrace);
  }
}