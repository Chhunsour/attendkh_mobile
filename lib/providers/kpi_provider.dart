import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/models/kpi_model.dart';
import 'package:mpg_hr_mobile_app/services/kpi_repository.dart';

final systemKpisProvider = FutureProvider<KpiData>((ref) async {
  return await KpiRepository.getSystemKpis();
});

final kpiTemplatesProvider = FutureProvider<List<KpiTemplateItem>>((ref) async {
  return await KpiRepository.getTemplates();
});

final kpiAssignmentsProvider =
    FutureProvider.family<List<EmployeeKpiItem>, String?>((ref, status) async {
  return await KpiRepository.getAssignments(status: status);
});

