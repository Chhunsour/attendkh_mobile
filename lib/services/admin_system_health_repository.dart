import 'package:attendkh/services/network/api_repository.dart';

class SystemServerInfo {
  final String phpVersion;
  final String laravelVersion;
  final double memoryUsageMb;
  final double memoryPeakMb;
  final String serverTime;
  final String timezone;

  const SystemServerInfo({
    this.phpVersion = '',
    this.laravelVersion = '',
    this.memoryUsageMb = 0,
    this.memoryPeakMb = 0,
    this.serverTime = '',
    this.timezone = '',
  });

  factory SystemServerInfo.fromJson(Map<String, dynamic> json) {
    return SystemServerInfo(
      phpVersion: json['php_version'] as String? ?? '',
      laravelVersion: json['laravel_version'] as String? ?? '',
      memoryUsageMb: (json['memory_usage_mb'] as num?)?.toDouble() ?? 0,
      memoryPeakMb: (json['memory_peak_mb'] as num?)?.toDouble() ?? 0,
      serverTime: json['server_time'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
    );
  }
}

class SystemDatabaseInfo {
  final String status;
  final String driver;
  final double sizeMb;
  final int tablesCount;

  const SystemDatabaseInfo({
    this.status = 'connected',
    this.driver = 'mysql',
    this.sizeMb = 0,
    this.tablesCount = 0,
  });

  factory SystemDatabaseInfo.fromJson(Map<String, dynamic> json) {
    return SystemDatabaseInfo(
      status: json['status'] as String? ?? 'connected',
      driver: json['driver'] as String? ?? 'mysql',
      sizeMb: (json['size_mb'] as num?)?.toDouble() ?? 0,
      tablesCount: json['tables_count'] as int? ?? 0,
    );
  }
}

class SystemQueueInfo {
  final String driver;
  final int pendingJobs;
  final int failedJobs;

  const SystemQueueInfo({
    this.driver = 'database',
    this.pendingJobs = 0,
    this.failedJobs = 0,
  });

  factory SystemQueueInfo.fromJson(Map<String, dynamic> json) {
    return SystemQueueInfo(
      driver: json['driver'] as String? ?? 'database',
      pendingJobs: json['pending_jobs'] as int? ?? 0,
      failedJobs: json['failed_jobs'] as int? ?? 0,
    );
  }
}

class SystemStorageInfo {
  final String disk;
  final double usedMb;

  const SystemStorageInfo({
    this.disk = 'public',
    this.usedMb = 0,
  });

  factory SystemStorageInfo.fromJson(Map<String, dynamic> json) {
    return SystemStorageInfo(
      disk: json['disk'] as String? ?? 'public',
      usedMb: (json['used_mb'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminSystemHealthData {
  final SystemServerInfo server;
  final SystemDatabaseInfo database;
  final SystemQueueInfo queue;
  final SystemStorageInfo storage;

  const AdminSystemHealthData({
    required this.server,
    required this.database,
    required this.queue,
    required this.storage,
  });

  factory AdminSystemHealthData.fromJson(Map<String, dynamic> json) {
    return AdminSystemHealthData(
      server: SystemServerInfo.fromJson(json['server'] as Map<String, dynamic>? ?? {}),
      database: SystemDatabaseInfo.fromJson(json['database'] as Map<String, dynamic>? ?? {}),
      queue: SystemQueueInfo.fromJson(json['queue'] as Map<String, dynamic>? ?? {}),
      storage: SystemStorageInfo.fromJson(json['storage'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AdminSystemHealthRepository {
  final ApiRepository _api;

  AdminSystemHealthRepository({ApiRepository? api})
      : _api = api ?? ApiRepository();

  /// GET /api/v1/admin/system-health
  Future<AdminSystemHealthData> getHealth() async {
    final response = await _api.get('/admin/system-health');
    if (response.data is Map<String, dynamic>) {
      return AdminSystemHealthData.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Invalid health response');
  }

  /// POST /api/v1/admin/system-health/clear-cache
  Future<void> clearCache() async {
    await _api.post('/admin/system-health/clear-cache');
  }

  /// POST /api/v1/admin/system-health/retry-jobs
  Future<void> retryJobs() async {
    await _api.post('/admin/system-health/retry-jobs');
  }
}
