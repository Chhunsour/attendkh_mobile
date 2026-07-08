import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/pages/hr/admin_employee_detail_screen.dart';

class AdminEmployeesScreen extends ConsumerWidget {
  const AdminEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Employees',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          employeesAsync.when(
            data: (employees) => employees.isEmpty
                ? const Center(child: Text('No employees found', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: employees.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final emp = employees[i];
                      return _EmployeeCard(employee: emp);
                    },
                  ),
            loading: () => const LoadingIndicator(message: 'Loading employees...'),
            error: (e, _) => Center(
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(employeesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.adminEmployeeForm),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  final EmployeeData employee;
  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminEmployeeDetailScreen(employee: employee),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withAlpha(26),
                backgroundImage: employee.avatar != null ? NetworkImage(employee.avatar!) : null,
                child: employee.avatar == null
                    ? Text(employee.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(employee.position ?? 'No Position', style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                    const SizedBox(height: 2),
                    Text(employee.department ?? 'No Department', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                  ],
                ),
              ),
              // Chevron hint
              Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 20),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                onPressed: () => context.push(AppRoutes.adminEmployeeForm, extra: employee),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(hrRepositoryProvider).deleteEmployee(employee.id);
        ref.invalidate(employeesProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${employee.name} deleted successfully'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to delete: $e'), backgroundColor: AppColors.danger));
      }
    }
  }
}
