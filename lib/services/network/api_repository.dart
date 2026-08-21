import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/services/network/exceptions.dart';

/// Standard API response envelope matching Laravel HttpResponse trait
class ApiResponse<T> {
  final String status;
  final String? message;
  final T? data;

  const ApiResponse({required this.status, this.message, this.data});

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      status: json['status'] ?? (json['message'] != null ? 'success' : 'error'),
      message: json['message'] as String?,
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : json['data'] as T?,
    );
  }
}

/// Base repository — provides HTTP methods with error handling
class ApiRepository {
  final Dio _dio;

  ApiRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// GET request with typed response
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    try {
      AppLogger.i('GET $path');
      final response = await _dio.get(path, queryParameters: queryParameters);
      final json = response.data as Map<String, dynamic>;

      // Non-envelope responses (like /user endpoint)
      if (json['status'] == null && json['data'] == null) {
        return ApiResponse(status: 'success', data: json as T);
      }

      return ApiResponse.fromJson(json, fromData);
    } on DioException catch (e) {
      AppLogger.e('GET $path failed', e.message);
      throw mapDioException(e);
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      AppLogger.i('POST $path');
      final response = await _dio.post(path, data: data);

      if (response.data is! Map<String, dynamic>) {
        throw AppException(
          message: 'Unexpected response format from server',
          statusCode: response.statusCode,
        );
      }

      final json = response.data as Map<String, dynamic>;

      if (json['status'] == null && json['data'] == null) {
        return ApiResponse(status: 'success', data: json as T);
      }

      return ApiResponse.fromJson(json, fromData);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.e('POST $path failed', e.message);
      throw mapDioException(e);
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      AppLogger.i('PUT $path');
      final response = await _dio.put(path, data: data);
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        fromData,
      );
    } on DioException catch (e) {
      AppLogger.e('PUT $path failed', e.message);
      throw mapDioException(e);
    }
  }

  /// DELETE request
  Future<void> delete(String path) async {
    try {
      AppLogger.i('DELETE $path');
      await _dio.delete(path);
    } on DioException catch (e) {
      AppLogger.e('DELETE $path failed', e.message);
      throw mapDioException(e);
    }
  }

  /// DOWNLOAD request
  Future<void> download(
    String path,
    String savePath, {
    dynamic data,
    String method = 'GET',
  }) async {
    try {
      AppLogger.i('DOWNLOAD $path to $savePath');

      final isGet = method.toUpperCase() == 'GET';

      await _dio.download(
        path,
        savePath,
        queryParameters: isGet && data is Map<String, dynamic> ? data : null,
        data: !isGet ? data : null,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      final message = await _readErrorMessage(e.response?.data);
      AppLogger.e(
        'DOWNLOAD $path failed [${e.response?.statusCode}]',
        message ?? e.message,
      );
      if (message != null && message.isNotEmpty) {
        throw AppException(message: message, statusCode: e.response?.statusCode);
      }
      throw mapDioException(e);
    }
  }

  /// Dio's download() streams the response, so a failed download hands back a
  /// ResponseBody stream instead of parsed JSON — read it, otherwise the
  /// server's real message is swallowed into a generic "Server error".
  Future<String?> _readErrorMessage(dynamic data) async {
    try {
      final String raw;
      if (data is ResponseBody) {
        final bytes = await data.stream.fold<List<int>>(
          <int>[],
          (acc, chunk) => acc..addAll(chunk),
        );
        raw = utf8.decode(bytes, allowMalformed: true);
      } else if (data is List<int>) {
        raw = utf8.decode(data, allowMalformed: true);
      } else if (data is String) {
        raw = data;
      } else if (data is Map) {
        return data['message']?.toString();
      } else {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      // Non-JSON body (HTML error page, binary) — fall back to status mapping.
    }
    return null;
  }
}
