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
}
