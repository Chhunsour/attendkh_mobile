import 'package:dio/dio.dart';

/// Base exception for the application
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'AppException: $message (status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Unauthorized', super.statusCode = 401});
}

class ForbiddenException extends AppException {
  const ForbiddenException({super.message = 'Forbidden', super.statusCode = 403});
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Not found', super.statusCode = 404});
}

class ValidationException extends AppException {
  final Map<String, List<String>> errors;

  const ValidationException({
    required String message,
    required this.errors,
    super.statusCode = 422,
  }) : super(message: message);

  @override
  String toString() => 'ValidationException: $message, errors: $errors';
}

class ServerException extends AppException {
  const ServerException({super.message = 'Server error', super.statusCode = 500});
}

class NoInternetException extends NetworkException {
  const NoInternetException() : super(message: 'No internet connection');
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super(message: 'Connection timed out');
}

/// Maps DioException to AppException
AppException mapDioException(DioException e) {
  // Check for no internet first
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    if (e.error?.toString().contains('No internet') == true) {
      return const NoInternetException();
    }
    return const TimeoutException();
  }

  final statusCode = e.response?.statusCode;

  switch (statusCode) {
    case 400:
      return AppException(message: 'Bad request', statusCode: 400);
    case 401:
      return const UnauthorizedException();
    case 403:
      return const ForbiddenException();
    case 404:
      return const NotFoundException();
    case 422:
      final errors = e.response?.data?['errors'] as Map<String, dynamic>?;
      return ValidationException(
        message: e.response?.data?['message'] ?? 'Validation failed',
        errors: errors?.map((k, v) => MapEntry(k, (v as List).cast<String>())) ?? {},
      );
    case 500:
    case 502:
    case 503:
      return const ServerException();
    default:
      return AppException(
        message: e.message ?? 'Unknown error',
        statusCode: statusCode,
      );
  }
}