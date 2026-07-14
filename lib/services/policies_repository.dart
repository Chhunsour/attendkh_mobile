import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart' show DepartmentData;

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
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      departmentId: json['department_id'] as int?,
      department: json['department'] != null ? DepartmentData.fromJson(json['department']) : null,
      version: json['version'] as String? ?? '1.0',
      status: json['status'] as String? ?? 'draft',
      effectiveDate: json['effective_date'] as String?,
      reviewDate: json['review_date'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class PoliciesResponse {
  final List<Policy> policies;
  final List<DepartmentData> departments;

  const PoliciesResponse({required this.policies, required this.departments});
}

class PoliciesRepository {
  final ApiRepository _api;
  PoliciesRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<PoliciesResponse> getAll({String? status, String? departmentId, String? search, int page = 1}) async {
    final Map<String, dynamic> query = {'page': page};
    if (status != null && status != 'all') query['status'] = status;
    if (departmentId != null && departmentId != 'all') query['department_id'] = departmentId;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _api.get('/company/policies', queryParameters: query);
    final data = response.data;
    
    List<Policy> pols = [];
    List<DepartmentData> depts = [];

    if (data is Map) {
      if (data['policies']?['data'] != null) {
        pols = (data['policies']['data'] as List).map((e) => Policy.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data['data'] != null) {
        pols = (data['data'] as List).map((e) => Policy.fromJson(e as Map<String, dynamic>)).toList();
      }
      
      if (data['departments'] != null) {
        depts = (data['departments'] as List).map((e) => DepartmentData.fromJson(e as Map<String, dynamic>)).toList();
      }
    } else if (data is List) {
      pols = data.map((e) => Policy.fromJson(e as Map<String, dynamic>)).toList();
    }

    return PoliciesResponse(policies: pols, departments: depts);
  }

  Future<Policy> createPolicy({
    required String title,
    required String content,
    String? departmentId,
    required String version,
    String? effectiveDate,
    String? reviewDate,
  }) async {
    final data = {
      'title': title,
      'content': content,
      if (departmentId != null && departmentId != 'all') 'department_id': departmentId,
      'version': version,
      if (effectiveDate != null && effectiveDate.isNotEmpty) 'effective_date': effectiveDate,
      if (reviewDate != null && reviewDate.isNotEmpty) 'review_date': reviewDate,
    };
    final response = await _api.post('/company/policies', data: data);
    return Policy.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updatePolicy(int id, {
    required String title,
    required String content,
    String? departmentId,
    required String version,
    String? effectiveDate,
    String? reviewDate,
  }) async {
    final data = {
      'title': title,
      'content': content,
      if (departmentId != null && departmentId != 'all') 'department_id': departmentId,
      'version': version,
      if (effectiveDate != null && effectiveDate.isNotEmpty) 'effective_date': effectiveDate,
      if (reviewDate != null && reviewDate.isNotEmpty) 'review_date': reviewDate,
    };
    await _api.put('/company/policies/$id', data: data);
  }

  Future<void> deletePolicy(int id) async => _api.delete('/company/policies/$id');
  Future<void> publishPolicy(int id) async => _api.post('/company/policies/$id/publish');
  Future<void> archivePolicy(int id) async => _api.post('/company/policies/$id/archive');
}