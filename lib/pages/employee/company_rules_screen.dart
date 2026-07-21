import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/network/api_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

final companyRulesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ApiRepository();
  final response = await api.get('/company/company-rules');
  if (response.data == null) return [];
  return (response.data as Map<String, dynamic>)['rules'] as List<dynamic>? ?? [];
});

class CompanyRulesScreen extends ConsumerWidget {
  const CompanyRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(companyRulesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Company Rules & Policies'),
        centerTitle: true,
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('No rules configured yet.', style: TextStyle(color: AppColors.grey500)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rule['title'] ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rule['description'] ?? '',
                      style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.grey700),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading rules...'),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(companyRulesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
