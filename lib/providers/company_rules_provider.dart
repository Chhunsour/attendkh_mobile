import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/company_rules_repository.dart';

final companyRulesRepositoryProvider = Provider<CompanyRulesRepository>((ref) {
  return CompanyRulesRepository();
});

final companyRulesProvider =
    FutureProvider.autoDispose<List<CompanyRule>>((ref) async {
  final repo = ref.watch(companyRulesRepositoryProvider);
  return repo.getCompanyRules();
});
