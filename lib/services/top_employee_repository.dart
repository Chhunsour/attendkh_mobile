import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/top_employee.dart';
import 'network/api_repository.dart';

final topEmployeeRepositoryProvider = Provider<TopEmployeeRepository>((ref) {
  return TopEmployeeRepository();
});

class TopEmployeeRepository extends ApiRepository {
  Future<Map<String, dynamic>> getTopEmployees(String month, {int? branchId}) async {
    final query = 'month=$month${branchId != null ? '&branch_id=$branchId' : ''}';
    final response = await get('/company/top-employees?$query');
    if (response.isSuccess && response.data != null) {
      final rawData = response.data;
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? ((rawData['data'] is Map<String, dynamic>) ? rawData['data'] as Map<String, dynamic> : rawData)
          : {};
      
      Map<String, dynamic> parsedData = {};
      data.forEach((categoryKey, categoryData) {
        if (categoryData is Map) {
          final byAmountList = categoryData['by_amount'];
          final byHoursList = categoryData['by_hours'];
          parsedData[categoryKey] = {
            'by_amount': (byAmountList is List)
                ? byAmountList.map((e) => TopEmployee.fromJson(Map<String, dynamic>.from(e as Map))).toList()
                : <TopEmployee>[],
            'by_hours': (byHoursList is List)
                ? byHoursList.map((e) => TopEmployee.fromJson(Map<String, dynamic>.from(e as Map))).toList()
                : <TopEmployee>[],
          };
        }
      });
      return parsedData;
    }
    throw Exception(response.message ?? 'Failed to load top employees');
  }
}
