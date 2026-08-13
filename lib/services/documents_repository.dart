import 'package:dio/dio.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class DepartmentData {
  final int id;
  final String name;

  const DepartmentData({required this.id, required this.name});

  factory DepartmentData.fromJson(Map<String, dynamic> json) {
    return DepartmentData(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
    );
  }
}

class DocumentData {
  final int id;
  final String title;
  final String? description;
  final int? departmentId;
  final DepartmentData? department;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final bool isPublic;
  final String? expiresAt;
  final String? createdAt;
  final String? uploaderName;
  final String? downloadUrl;

  const DocumentData({
    required this.id,
    required this.title,
    this.description,
    this.departmentId,
    this.department,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.isPublic = false,
    this.expiresAt,
    this.createdAt,
    this.uploaderName,
    this.downloadUrl,
  });

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    return DocumentData(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Document',
      description: json['description'] as String?,
      departmentId: json['department_id'] as int?,
      department: json['department'] != null
          ? DepartmentData.fromJson(json['department'])
          : null,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] is int
          ? json['file_size'] as int
          : int.tryParse(json['file_size']?.toString() ?? ''),
      mimeType: json['mime_type'] as String?,
      isPublic:
          json['is_public'] == true ||
          json['is_public'] == 1 ||
          json['is_public'] == '1' ||
          json['is_public'] == 'true',
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String?,
      uploaderName: json['uploader']?['name'] as String?,
      downloadUrl: json['download_url'] as String?,
    );
  }
}

class DocumentsResponse {
  final List<DocumentData> documents;
  final List<DepartmentData> departments;
  final int currentPage;
  final int lastPage;
  final int total;
  final int from;
  final int to;

  const DocumentsResponse({
    required this.documents,
    required this.departments,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.from = 0,
    this.to = 0,
  });
}

class DocumentsRepository {
  final ApiRepository _api;
  DocumentsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<DocumentsResponse> getDocuments({
    String? departmentId,
    String? search,
    int page = 1,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (departmentId != null && departmentId != 'all') {
      query['department_id'] = departmentId;
    }
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _api.get(
      '/company/documents',
      queryParameters: query,
    );
    final data = response.data;

    List<DocumentData> docs = [];
    List<DepartmentData> depts = [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;
    int from = 0;
    int to = 0;

    if (data is Map) {
      if (data['documents']?['data'] != null) {
        final docsMap = data['documents'] as Map;
        docs = (docsMap['data'] as List)
            .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
            .toList();
        currentPage = (docsMap['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (docsMap['last_page'] as num?)?.toInt() ?? 1;
        total = (docsMap['total'] as num?)?.toInt() ?? 0;
        from = (docsMap['from'] as num?)?.toInt() ?? 0;
        to = (docsMap['to'] as num?)?.toInt() ?? 0;
      } else if (data['data'] != null) {
        docs = (data['data'] as List)
            .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (data['departments'] != null) {
        depts = (data['departments'] as List)
            .map((e) => DepartmentData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (data is List) {
      docs = data
          .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DocumentsResponse(
      documents: docs,
      departments: depts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      from: from,
      to: to,
    );
  }

  Future<DocumentData> uploadDocument({
    required String filePath,
    required String title,
    String? description,
    String? departmentId,
    bool isPublic = false,
    String? expiresAt,
  }) async {
    final file = await MultipartFile.fromFile(filePath);
    final formData = FormData.fromMap({
      'file': file,
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (departmentId != null &&
          departmentId.isNotEmpty &&
          departmentId != 'all')
        'department_id': departmentId,
      'is_public': isPublic ? 1 : 0,
      if (expiresAt != null && expiresAt.isNotEmpty) 'expires_at': expiresAt,
    });

    final response = await _api.post('/company/documents', data: formData);
    return DocumentData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateDocument(
    int id, {
    required String title,
    String? description,
    String? departmentId,
    bool isPublic = false,
    String? expiresAt,
    String? filePath,
  }) async {
    if (filePath != null && filePath.isNotEmpty) {
      final file = await MultipartFile.fromFile(filePath);
      final formData = FormData.fromMap({
        '_method': 'PUT',
        'file': file,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (departmentId != null &&
            departmentId.isNotEmpty &&
            departmentId != 'all')
          'department_id': departmentId,
        'is_public': isPublic ? 1 : 0,
        if (expiresAt != null && expiresAt.isNotEmpty) 'expires_at': expiresAt,
      });
      await _api.post('/company/documents/$id', data: formData);
    } else {
      final data = {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (departmentId != null &&
            departmentId.isNotEmpty &&
            departmentId != 'all')
          'department_id': departmentId,
        'is_public': isPublic ? 1 : 0,
        if (expiresAt != null && expiresAt.isNotEmpty) 'expires_at': expiresAt,
      };
      await _api.put('/company/documents/$id', data: data);
    }
  }

  Future<void> downloadDocument(int id, String savePath) async {
    await _api.download(
      '/company/documents/$id/download',
      savePath,
      method: 'GET',
    );
  }

  Future<void> deleteDocument(int id) async =>
      _api.delete('/company/documents/$id');

  // Employee endpoint
  Future<List<DocumentData>> getEmployeeDocuments() async {
    final response = await _api.get('/company/my-documents');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map && data['data'] != null) {
      return (data['data'] as List)
          .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
