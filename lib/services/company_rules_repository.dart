import 'package:attendkh/services/network/api_repository.dart';

class CompanyRule {
  final String title;
  final String description;

  const CompanyRule({required this.title, required this.description});

  factory CompanyRule.fromJson(Map<String, dynamic> json) {
    return CompanyRule(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class CompanyRulesRepository {
  final ApiRepository _api;
  CompanyRulesRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<CompanyRule>> getCompanyRules() async {
    final response = await _api.get('/company/company-rules');
    final data = response.data;

    List<dynamic> rawList = [];
    if (data is Map) {
      if (data['rules'] is List) {
        rawList = data['rules'] as List;
      } else if (data['data'] is List) {
        rawList = data['data'] as List;
      }
    } else if (data is List) {
      rawList = data;
    }

    return rawList
        .map((e) => CompanyRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
