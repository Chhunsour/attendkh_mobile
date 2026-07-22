import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/services/policies_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

final employeePoliciesProvider = FutureProvider.autoDispose<List<Policy>>((ref) async {
  final repo = PoliciesRepository();
  return repo.getEmployeePolicies();
});

class PoliciesScreen extends ConsumerStatefulWidget {
  const PoliciesScreen({super.key});

  @override
  ConsumerState<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends ConsumerState<PoliciesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(employeePoliciesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Company Policies'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Action Required'),
            Tab(text: 'Acknowledged'),
          ],
        ),
      ),
      body: policiesAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (policies) {
          final unread = policies.where((p) => !p.isAcknowledged).toList();
          final read = policies.where((p) => p.isAcknowledged).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPolicyList(unread, emptyMessage: 'All policies have been acknowledged!'),
              _buildPolicyList(read, emptyMessage: 'You have not acknowledged any policies yet.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPolicyList(List<Policy> policies, {required String emptyMessage}) {
    if (policies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.grey300),
              const SizedBox(height: 16),
              Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey600, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: policies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final policy = policies[index];
        return InkWell(
          onTap: () => _openPolicyDetail(policy),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: policy.isAcknowledged ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    policy.isAcknowledged ? Icons.verified : Icons.warning_amber_rounded,
                    color: policy.isAcknowledged ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(policy.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900)),
                      const SizedBox(height: 4),
                      Text('Version ${policy.version}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPolicyDetail(Policy policy) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PolicyDetailScreen(
        policy: policy, 
        onAcknowledged: () {
          ref.invalidate(employeePoliciesProvider);
        }
      ),
    ));
  }
}

class PolicyDetailScreen extends StatefulWidget {
  final Policy policy;
  final VoidCallback onAcknowledged;

  const PolicyDetailScreen({super.key, required this.policy, required this.onAcknowledged});

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  bool _submitting = false;

  Future<void> _handleAcknowledge() async {
    setState(() => _submitting = true);
    try {
      final repo = PoliciesRepository();
      await repo.acknowledgePolicy(widget.policy.id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy acknowledged successfully.')));
      widget.onAcknowledged();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Policy Document'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.policy.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4)),
                        child: Text('Version ${widget.policy.version}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      if (widget.policy.department != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.policy.department!.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    widget.policy.content,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.grey800),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (widget.policy.isAcknowledged)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(top: BorderSide(color: Colors.green.shade200)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Acknowledged on ${widget.policy.acknowledgedAt?.split("T").first ?? ""}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleAcknowledge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('I have read and acknowledge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
