import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';

class AssignedShift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String? date;
  final String? color;

  const AssignedShift({required this.id, required this.name, required this.startTime, required this.endTime, this.date, this.color});

  factory AssignedShift.fromJson(Map<String, dynamic> json) {
    return AssignedShift(
      id: json['id'] as int,
      name: json['shift']?['name'] as String? ?? json['name'] as String? ?? '',
      startTime: json['shift']?['start_time'] as String? ?? json['start_time'] as String? ?? '',
      endTime: json['shift']?['end_time'] as String? ?? json['end_time'] as String? ?? '',
      date: json['date'] as String?,
      color: json['shift']?['color'] as String?,
    );
  }
}

class ShiftsRepository {
  final ApiRepository _api;
  ShiftsRepository({ApiRepository? api}) : _api = api ?? ApiRepository();

  Future<List<AssignedShift>> getMine({String? month}) async {
    final response = await _api.get(
      '/company/shifts',
      queryParameters: {'month': ?month},
    );
    final data = response.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(AssignedShift.fromJson).toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().map(AssignedShift.fromJson).toList();
    }
    return [];
  }
}