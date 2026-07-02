import 'package:mpg_hr_mobile_app/core/network/api_repository.dart';

class DocumentData {
  final int id;
  final String name;
  final String? fileName;
  final String? fileSize;
  final String? category;
  final String? uploadedAt;
  final String? downloadUrl;

  const DocumentData({required this.id, required this.name, this.fileName, this.fileSize, this.category, this.uploadedAt, this.downloadUrl});

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    return DocumentData(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['title'] as String? ?? 'Document',
      fileName: json['file_name'] as String? ?? json['name'] as String?,
      fileSize: json['file_size'] as String? ?? '${json['size'] ?? '?'} KB',
      category: json['category'] as String?,
      uploadedAt: json['uploaded_at'] as String? ?? json['created_at'] as String?,
      downloadUrl: json['download_url'] as String? ?? json['url'] as String?,
    );
  }
}

class DocumentsRepository {
  final ApiRepository _api;
  DocumentsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<DocumentData>> getDocuments() async {
    final response = await _api.get('/company/documents');
    final data = response.data;
    if (data is List) return data.map((e) => DocumentData.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => DocumentData.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}