import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/holidays/data/holidays_repository.dart';

final holidaysRepositoryProvider = Provider<HolidaysRepository>((ref) => HolidaysRepository());

final holidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) async {
  final repo = ref.watch(holidaysRepositoryProvider);
  return repo.getAll();
});