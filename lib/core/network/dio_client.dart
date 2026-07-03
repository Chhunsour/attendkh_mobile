import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mpg_hr_mobile_app/core/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/core/storage/secure_storage.dart';

class DioClient {
  static Dio? _dio;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
      throw StateError('DioClient not initialized. Call DioClient.init() first.');
    }
    return _dio!;
  }

  /// Creates a new Dio instance from scratch (for testing or custom configs)
  static Dio createDio({String? baseUrl}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'http://localhost:8000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      AppLogger.w('401 Unauthorized - token may be expired');
      // Future: trigger refresh token flow or logout
    }
    handler.next(err);
  }
}

class _TenantInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final companyId = await SecureStorageService.instance.companyId;
    if (companyId != null && companyId.isNotEmpty) {
      options.headers['X-Company-Id'] = companyId;
    }
    handler.next(options);
  }
}

class _ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No internet connection',
        ),
      );
      return;
    }
    handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      '➡️ ${options.method} ${options.uri}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
      '✅ ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ ${err.response?.statusCode} ${err.requestOptions.uri}',
      err.message,
    );
    handler.next(err);
  }
}

/// Helper extension for API calls
extension DioResponseX on Response {
  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;

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