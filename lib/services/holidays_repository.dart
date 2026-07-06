import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class Holiday {
  final int id;
  final String name;
  final String date;
  final String? description;
  final bool? isRecurring;

  const Holiday({required this.id, required this.name, required this.date, this.description, this.isRecurring});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String?,
      isRecurring: json['is_recurring'] as bool?,
    );
  }
}

class HolidaysRepository {
  final ApiRepository _api;
  HolidaysRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<Holiday>> getAll({int? year}) async {
    final response = await _api.get('/company/holidays', queryParameters: {if (year != null) 'year': year.toString()});
    final data = response.data;
    if (data is List) return data.map((e) => Holiday.fromJson(e as Map<String, dynamic>)).toList();
    if (data is Map && data['data'] != null) return (data['data'] as List).map((e) => Holiday.fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }
}