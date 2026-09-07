import 'package:attendkh/services/network/api_repository.dart';
import 'package:attendkh/services/documents_repository.dart'
    show DepartmentData;

class PolicyStats {
  final int target;
  final int acknowledged;
  final int percentage;

  const PolicyStats({
    required this.target,
    required this.acknowledged,
    required this.percentage,
  });

  factory PolicyStats.fromJson(Map<String, dynamic> json) {
    return PolicyStats(
      target: json['target'] as int? ?? 0,
      acknowledged: json['acknowledged'] as int? ?? 0,
      percentage: json['percentage'] as int? ?? 0,
    );
  }
}

class Policy {
  final int id;
  final String title;
  final String content;
  final int? departmentId;
  final DepartmentData? department;
  final String version;
  final String status;
  final String? effectiveDate;
  final String? reviewDate;
  final String createdAt;
  final PolicyStats? stats;
  final String? creatorName;

  // Employee context fields
  final bool isAcknowledged;
  final String? acknowledgedAt;

  const Policy({
    required this.id,
    required this.title,
    required this.content,
    this.departmentId,
    this.department,
    required this.version,
    required this.status,
    this.effectiveDate,
    this.reviewDate,
    required this.createdAt,
    this.stats,
    this.creatorName,
    this.isAcknowledged = false,
    this.acknowledgedAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      departmentId: json['department_id'] as int?,
      department: json['department'] != null
          ? DepartmentData.fromJson(json['department'])
          : null,
      version: json['version'] as String? ?? '1.0',
      status: json['status'] as String? ?? 'draft',
      effectiveDate: json['effective_date'] as String?,
      reviewDate: json['review_date'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      stats: json['stats'] != null
          ? PolicyStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      creatorName:
          json['creator']?['name'] as String? ??
          json['created_by_name'] as String?,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] as String?,
    );
  }
}

class PoliciesResponse {
  final List<Policy> policies;
  final List<DepartmentData> departments;
  final int currentPage;
  final int lastPage;
  final int total;
  final int from;
  final int to;

  const PoliciesResponse({
    required this.policies,
    required this.departments,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
  });
}

class PoliciesRepository {
  final ApiRepository _api;
  PoliciesRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<PoliciesResponse> getAll({
    String? status,
    String? departmentId,
    String? search,
    int page = 1,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'sort': sort,
      'order': order,
    };
    if (status != null && status != 'all') query['status'] = status;
    if (departmentId != null && departmentId != 'all') {
      query['department_id'] = departmentId;
    }
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _api.get(
      '/company/policies',
      queryParameters: query,
    );
    final data = response.data;

    List<Policy> pols = [];
    List<DepartmentData> depts = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;
    int from = 0;
    int to = 0;

    if (data is Map) {
      if (data['policies']?['data'] != null) {
        final pag = data['policies'] as Map;
        pols = (pag['data'] as List)
            .map((e) => Policy.fromJson(e as Map<String, dynamic>))
            .toList();
        currentPage = (pag['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (pag['last_page'] as num?)?.toInt() ?? 1;
        total = (pag['total'] as num?)?.toInt() ?? 0;
        from = (pag['from'] as num?)?.toInt() ?? 0;
        to = (pag['to'] as num?)?.toInt() ?? 0;
      } else if (data['data'] != null && data['data'] is List) {
        pols = (data['data'] as List)
            .map((e) => Policy.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data['departments'] != null) {
        depts = (data['departments'] as List)
            .map((e) => DepartmentData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (data is List) {
      pols = data
          .map((e) => Policy.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PoliciesResponse(
      policies: pols,
      departments: depts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      from: from,
      to: to,
    );
  }

  Future<Policy> createPolicy({
    required String title,
    required String content,
    String? departmentId,
    required String version,
    String? status,
    String? effectiveDate,
    String? reviewDate,
  }) async {
    final data = {
      'title': title,
      'content': content,
      if (departmentId != null && departmentId != 'all')
        'department_id': departmentId,
      'version': version,
      if (status != null && status.isNotEmpty) 'status': status,
      if (effectiveDate != null && effectiveDate.isNotEmpty)
        'effective_date': effectiveDate,
      if (reviewDate != null && reviewDate.isNotEmpty)
        'review_date': reviewDate,
    };
    final response = await _api.post('/company/policies', data: data);
    return Policy.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updatePolicy(
    int id, {
    required String title,
    required String content,
    String? departmentId,
    required String version,
    String? status,
    String? effectiveDate,
    String? reviewDate,
  }) async {
    final data = {
      'title': title,
      'content': content,
      if (departmentId != null && departmentId != 'all')
        'department_id': departmentId,
      'version': version,
      if (status != null && status.isNotEmpty) 'status': status,
      if (effectiveDate != null && effectiveDate.isNotEmpty)
        'effective_date': effectiveDate,
      if (reviewDate != null && reviewDate.isNotEmpty)
        'review_date': reviewDate,
    };
    await _api.put('/company/policies/$id', data: data);
  }

  Future<void> deletePolicy(int id) async =>
      _api.delete('/company/policies/$id');
  Future<void> publishPolicy(int id) async =>
      _api.post('/company/policies/$id/publish');
  Future<void> archivePolicy(int id) async =>
      _api.post('/company/policies/$id/archive');

  // ---------------------------------------------------------------------------
  // Employee Endpoints
  // ---------------------------------------------------------------------------

  /// Fetches published policies visible to the employee.
  /// Uses /company/my-policies (Employee self-service endpoint).
  Future<List<Policy>> getEmployeePolicies() async {
    final response = await _api.get('/company/my-policies');
    final data = response.data;

    List<dynamic> rawList = [];

    if (data is Map) {
      if (data['data'] is List) {
        rawList = data['data'] as List;
      } else if (data['policies'] is List) {
        rawList = data['policies'] as List;
      }
    } else if (data is List) {
      rawList = data;
    }

    return rawList.map((item) {
      final json = item as Map<String, dynamic>;
      return Policy.fromJson(json);
    }).toList();
  }

  Future<Policy> getEmployeePolicy(int id) async {
    final response = await _api.get('/company/my-policies/$id');
    final data = response.data;
    if (data is Map && data['data'] != null) {
      return Policy.fromJson(data['data'] as Map<String, dynamic>);
    }
    return Policy.fromJson(data as Map<String, dynamic>);
  }

  Future<void> acknowledgePolicy(int id) async {
    await _api.post('/company/my-policies/$id/acknowledge');
  }
}
