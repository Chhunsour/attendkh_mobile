import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminPoliciesScreen extends ConsumerStatefulWidget {
  const AdminPoliciesScreen({super.key});

  @override
  ConsumerState<AdminPoliciesScreen> createState() => _AdminPoliciesScreenState();
}

class _AdminPoliciesScreenState extends ConsumerState<AdminPoliciesScreen> {
  late Future<List<Policy>> _policiesFuture;

  @override
  void initState() {
    super.initState();
    _policiesFuture = PoliciesRepository().getAll();
  }

  void _refresh() {
    setState(() {
      _policiesFuture = PoliciesRepository().getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Policies',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<Policy>>(
        future: _policiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading policies...');
          }
          if (snapshot.hasError) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No policies', style: TextStyle(color: AppColors.grey400)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = items[i];
              final statusColor = p.status == 'published'
                  ? AppColors.success
                  : p.status == 'draft'
                      ? AppColors.warning
                      : AppColors.grey500;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.policy, color: AppColors.info, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          Text(
                            p.category,
                            style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.status.substring(0, 1).toUpperCase() + p.status.substring(1),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                ),
                              ),
                              if (p.effectiveDate != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Effective: ${p.effectiveDate}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.grey400, size: 20),
                      onSelected: (action) async {
                        final opsRepo = AdminOperationsRepository();
                        try {
                          if (action == 'publish') {
                            await opsRepo.publishPolicy(p.id);
                          } else if (action == 'archive') {
                            await opsRepo.archivePolicy(p.id);
                          }
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Policy ${action}d'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'publish',
                          child: Row(children: [
                            Icon(Icons.publish, size: 18),
                            SizedBox(width: 8),
                            Text('Publish'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(children: [
                            Icon(Icons.archive, size: 18),
                            SizedBox(width: 8),
                            Text('Archive'),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}