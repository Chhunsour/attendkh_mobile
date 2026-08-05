import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';

final policiesRepositoryProvider = Provider<PoliciesRepository>(
  (ref) => PoliciesRepository(),
);

final policiesProvider = FutureProvider<PoliciesResponse>((ref) async {
  final repo = ref.watch(policiesRepositoryProvider);
  return repo.getAll();
});