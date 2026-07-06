import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/shifts_repository.dart';

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) => ShiftsRepository());

final myShiftsProvider = FutureProvider.autoDispose<List<AssignedShift>>((ref) async {
  final repo = ref.watch(shiftsRepositoryProvider);
  return repo.getMine();
});