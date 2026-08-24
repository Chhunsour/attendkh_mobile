import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

class KpiRepository {
  static Future<KpiData> getSystemKpis() async {
    try {
      final response = await DioClient.instance.get('/company/kpis');
      return KpiData.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load system KPIs: $e');
    }
  }

  static Future<List<KpiTemplateItem>> getTemplates() async {
    try {
      final response = await DioClient.instance.get('/company/kpis/templates');
      final list = (response.data['data'] as List?) ?? [];
      return list.map((e) => KpiTemplateItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load KPI templates: $e');
    }
  }

  static Future<void> createTemplate(Map<String, dynamic> data) async {
    try {
      await DioClient.instance.post('/company/kpis/templates', data: data);
    } catch (e) {
      throw Exception('Failed to create KPI template: $e');
    }
  }

  static Future<void> deleteTemplate(int id) async {
    try {
      await DioClient.instance.delete('/company/kpis/templates/$id');
    } catch (e) {
      throw Exception('Failed to delete KPI template: $e');
    }
  }

  static Future<List<EmployeeKpiItem>> getAssignments({String? status, int? employeeId}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'all') {
        query['status'] = status;
      }
      if (employeeId != null) {
        query['employee_id'] = employeeId;
      }
      final response = await DioClient.instance.get(
        '/company/kpis/assignments',
        queryParameters: query,
      );
      final list = (response.data['data'] as List?) ?? [];
      return list.map((e) => EmployeeKpiItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load assigned KPIs: $e');
    }
  }

  static Future<void> assignKpi(Map<String, dynamic> data) async {
    try {
      await DioClient.instance.post('/company/kpis/assignments', data: data);
    } catch (e) {
      throw Exception('Failed to assign KPI: $e');
    }
  }

  static Future<void> evaluateKpi(
    int id, {
    required num actualValue,
    required String status,
    String? managerNotes,
  }) async {
    try {
      await DioClient.instance.post(
        '/company/kpis/assignments/$id/evaluate',
        data: {
          'actual_value': actualValue,
          'status': status,
          'manager_notes': managerNotes,
        },
      );
    } catch (e) {
      throw Exception('Failed to evaluate KPI: $e');
    }
  }

  static Future<void> updateProgress(
    int id, {
    required num actualValue,
    String? employeeNotes,
  }) async {
    try {
      await DioClient.instance.post(
        '/company/kpis/assignments/$id/progress',
        data: {
          'actual_value': actualValue,
          'employee_notes': employeeNotes,
        },
      );
    } catch (e) {
      throw Exception('Failed to update KPI progress: $e');
    }
  }

  static Future<void> deleteAssignment(int id) async {
    try {
      await DioClient.instance.delete('/company/kpis/assignments/$id');
    } catch (e) {
      throw Exception('Failed to delete KPI assignment: $e');
    }
  }
}
