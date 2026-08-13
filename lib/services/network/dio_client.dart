import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/utils/storage/secure_storage.dart';

/// Base URL for the Laravel backend.
/// - Android Emulator : 10.0.2.2 maps to the host machine's localhost.
/// - Real device (WiFi): Use the Mac's LAN IP so the device can reach the server.
/// Change [_devServerIp] to match your machine's current IP when on a real device.
const String _devServerIp = '10.0.2.2:8000';
const String _r2StorageUrl =
    'https://pub-ccd9b4a59b6e4eddb12ef2a2c45e75c7.r2.dev';

String get _baseUrl {
  return 'http://$_devServerIp/api';
}

class DioClient {
  static Dio? _dio;

  static String get storageUrl => _r2StorageUrl;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Content-Type-Options': 'nosniff',
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    _dio!.interceptors.addAll([
      _AuthInterceptor(),
      _TenantInterceptor(),
      _ConnectivityInterceptor(),
      _LoggingInterceptor(),
    ]);

    AppLogger.i('DioClient initialized');
  }

  static Dio get instance {
    if (_dio == null) {
      throw StateError(
        'DioClient not initialized. Call DioClient.init() first.',
      );
    }
    return _dio!;
  }

  /// Creates a new Dio instance from scratch (for testing or custom configs)
  static Dio createDio({String? baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = SecureStorageService.instance.cachedAccessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      AppLogger.w('401 Unauthorized - clearing token session');
      await SecureStorageService.instance.clearAuth();
    }
    handler.next(err);
  }
}

class _TenantInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final companyId = SecureStorageService.instance.cachedCompanyId;
    if (companyId != null && companyId.isNotEmpty) {
      options.headers['X-Company-Id'] = companyId;
    }
    handler.next(options);
  }
}

class _ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Pass straight to network execution; Dio connectionTimeout handles offline errors without pre-flight platform IPC delay
    handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.d('➡️ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.d('✅ ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.e(
        '❌ ${err.response?.statusCode} ${err.requestOptions.uri}',
        'Message: ${err.message}',
      );
    }
    handler.next(err);
  }
}

/// Helper extension for API calls
extension DioResponseX on Response {
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  bool get isUnauthorized => statusCode == 401;

  bool get isValidationError => statusCode == 422;

  bool get isNotFound => statusCode == 404;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Extract data from standard API envelope {data, message, errors}
  dynamic get apiData => data?['data'];

  String? get apiMessage => data?['message'] as String?;

  Map<String, List<String>>? get apiErrors {
    if (data?['errors'] == null) return null;
    final errors = data!['errors'] as Map<String, dynamic>;
    return errors.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.cast<String>());
      }
      return MapEntry(key, [value.toString()]);
    });
  }
}
