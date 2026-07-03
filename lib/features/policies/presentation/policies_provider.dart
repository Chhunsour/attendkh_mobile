import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/features/policies/data/policies_repository.dart';

final policiesRepositoryProvider = Provider<PoliciesRepository>(
  (ref) => PoliciesRepository(),
);

final policiesProvider = FutureProvider.autoDispose<List<Policy>>((ref) async {
  final repo = ref.watch(policiesRepositoryProvider);
  return repo.getAll();
});