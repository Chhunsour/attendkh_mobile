import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/top_employee.dart';
import 'network/api_repository.dart';

final topEmployeeRepositoryProvider = Provider<TopEmployeeRepository>((ref) {
  return TopEmployeeRepository();
});

class TopEmployeeRepository extends ApiRepository {
  Future<Map<String, dynamic>> getTopEmployees(String month) async {
    final response = await get('/company/top-employees?month=$month');
    if (response.isSuccess) {
      final Map<String, dynamic> data = response.data['data'];
      
      Map<String, dynamic> parsedData = {};
      data.forEach((categoryKey, categoryData) {
        parsedData[categoryKey] = {
          'by_amount': (categoryData['by_amount'] as List).map((e) => TopEmployee.fromJson(e)).toList(),
          'by_hours': (categoryData['by_hours'] as List).map((e) => TopEmployee.fromJson(e)).toList(),
        };
      });
      return parsedData;
    }
    throw Exception(response.message ?? 'Failed to load top employees');
  }
}
