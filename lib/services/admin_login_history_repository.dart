import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AdminLoginHistory {
  final int id;
  final String? email;
  final String? userName;
  final String? companyName;
  final String? ipAddress;
  final String? device;
  final String platform;
  final String status;
  final String? failureReason;
  final String? createdAt;

  const AdminLoginHistory({
    required this.id,
    this.email,
    this.userName,
    this.companyName,
    this.ipAddress,
    this.device,
    required this.platform,
    required this.status,
    this.failureReason,
    this.createdAt,
  });

  factory AdminLoginHistory.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final company = json['company'] as Map<String, dynamic>?;

    return AdminLoginHistory(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String?,
      userName: user?['name'] as String?,
      companyName: company?['name'] as String?,
      ipAddress: json['ip_address'] as String?,
      device: json['device'] as String?,
      platform: json['platform'] as String? ?? 'web',
      status: json['status'] as String? ?? 'success',
      failureReason: json['failure_reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class AdminLoginMetrics {
  final int totalToday;
  final int successToday;
  final int failedToday;
  final int mobileToday;

  const AdminLoginMetrics({
    this.totalToday = 0,
    this.successToday = 0,
    this.failedToday = 0,
    this.mobileToday = 0,
  });

  factory AdminLoginMetrics.fromJson(Map<String, dynamic> json) {
    return AdminLoginMetrics(
      totalToday: json['total_today'] as int? ?? 0,
      successToday: json['success_today'] as int? ?? 0,
      failedToday: json['failed_today'] as int? ?? 0,
      mobileToday: json['mobile_today'] as int? ?? 0,
    );
  }
}

class AdminLoginHistoryResult {
  final List<AdminLoginHistory> histories;
  final AdminLoginMetrics metrics;

  const AdminLoginHistoryResult({
    required this.histories,
    required this.metrics,
  });
}

class AdminLoginHistoryRepository {
  final ApiRepository _api;

  AdminLoginHistoryRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/login-history
  Future<AdminLoginHistoryResult> getHistories({
    String? search,
    String? status,
    String? platform,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (platform != null && platform.isNotEmpty) queryParams['platform'] = platform;

    final response = await _api.get(
      '/admin/login-history',
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final historiesMap = map['histories'] as Map<String, dynamic>?;
      final listData = (historiesMap?['data'] as List<dynamic>?) ??
          (map['data'] as List<dynamic>?) ??
          [];

      final histories = listData
          .map((e) => AdminLoginHistory.fromJson(e as Map<String, dynamic>))
          .toList();

      final metricsMap = map['metrics'] as Map<String, dynamic>? ?? {};
      final metrics = AdminLoginMetrics.fromJson(metricsMap);

      return AdminLoginHistoryResult(histories: histories, metrics: metrics);
    }

    return const AdminLoginHistoryResult(
      histories: [],
      metrics: AdminLoginMetrics(),
    );
  }
}
