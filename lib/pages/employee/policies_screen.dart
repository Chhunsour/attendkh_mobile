import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/providers/policies_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class PoliciesScreen extends ConsumerWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(policiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: policiesAsync.when(
        data: (policies) {
          if (policies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.policy_outlined, size: 64, color: AppColors.grey300),
                  SizedBox(height: 16),
                  Text('No policies available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                  SizedBox(height: 8),
                  Text('Company policies will appear here.', style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                ],
              ),
            );
          }

          // Group by category
          final categories = <String, List<Policy>>{};
          for (final p in policies) {
            categories.putIfAbsent(p.category, () => []).add(p);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: categories.entries.map((entry) {
              return _CategorySection(
                category: _categoryLabel(entry.key),
                icon: _categoryIcon(entry.key),
                color: _categoryColor(entry.key),
                policies: entry.value,
              );
            }).toList(),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading policies...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(policiesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String key) {
    switch (key) {
      case 'hr': return 'HR';
      case 'safety': return 'Safety';
      case 'it': return 'IT';
      case 'finance': return 'Finance';
      default: return 'General';
    }
  }

  IconData _categoryIcon(String key) {
    switch (key) {
      case 'hr': return Icons.people_outline;
      case 'safety': return Icons.health_and_safety_outlined;
      case 'it': return Icons.computer_outlined;
      case 'finance': return Icons.account_balance_outlined;
      default: return Icons.description_outlined;
    }
  }

  Color _categoryColor(String key) {
    switch (key) {
      case 'hr': return AppColors.secondary;
      case 'safety': return AppColors.danger;
      case 'it': return AppColors.info;
      case 'finance': return AppColors.success;
      default: return AppColors.warning;
    }
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final IconData icon;
  final Color color;
  final List<Policy> policies;

  const _CategorySection({
    required this.category,
    required this.icon,
    required this.color,
    required this.policies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 8),
            Text('(${policies.length})', style: const TextStyle(fontSize: 13, color: AppColors.grey400)),
          ],
        ),
        const SizedBox(height: 8),
        ...policies.map((p) => _PolicyCard(policy: p)),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final Policy policy;
  const _PolicyCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(policy.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.grey800)),
                const SizedBox(height: 4),
                Text(policy.content, style: const TextStyle(fontSize: 12, color: AppColors.grey500), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('v${policy.version}', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                    const SizedBox(width: 12),
                    if (policy.effectiveDate != null)
                      Text('Effective: ${policy.effectiveDate}', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: policy.status == 'published' ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              policy.status == 'published' ? 'Active' : policy.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: policy.status == 'published' ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}