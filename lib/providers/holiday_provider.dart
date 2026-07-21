import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/holidays_repository.dart';

final holidaysRepositoryProvider = Provider<HolidaysRepository>((ref) {
  return HolidaysRepository();
});

final employeeHolidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final repo = ref.watch(holidaysRepositoryProvider);
  return await repo.getAll();
});
