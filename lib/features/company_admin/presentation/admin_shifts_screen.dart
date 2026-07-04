import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AdminShiftsScreen extends ConsumerWidget {
  const AdminShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          shiftsAsync.when(
            data: (shifts) => shifts.isEmpty
                ? const Center(child: Text('No shifts found', style: TextStyle(color: AppColors.grey400)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shifts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final shift = shifts[i];
                      return _ShiftCard(shift: shift);
                    },
                  ),
            loading: () => const LoadingIndicator(message: 'Loading shifts...'),
            error: (e, _) => Center(
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(shiftsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.adminShiftForm),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftCard extends ConsumerWidget {
  final ShiftData shift;
  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(shift.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
              IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20), onPressed: () => context.push(AppRoutes.adminShiftForm, extra: shift)),
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20), onPressed: () => _delete(context, ref)),
            ],
          ),
          Text('${shift.startTime} - ${shift.endTime}', style: TextStyle(color: AppColors.grey600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Expanded(child: Text(shift.workDays?.join(', ') ?? 'No days set', style: TextStyle(color: AppColors.grey500, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Text('${shift.employeesCount ?? 0} Employees Assigned', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAssignDialog(context, ref),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Assign Employee'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content: Text('Are you sure you want to delete ${shift.name}?'),
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
        await ref.read(adminOpsRepositoryProvider).deleteShift(shift.id);
        ref.invalidate(shiftsProvider);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${shift.name} deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to delete: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _showAssignDialog(BuildContext context, WidgetRef ref) async {
    // To properly fetch employees, let's use a dialog that loads them.
    

    showDialog(
      context: context,
      builder: (ctx) => _AssignShiftDialog(shift: shift),
    );
  }
}

class _AssignShiftDialog extends ConsumerStatefulWidget {
  final ShiftData shift;
  const _AssignShiftDialog({required this.shift});

  @override
  ConsumerState<_AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends ConsumerState<_AssignShiftDialog> {
  int? _selectedEmployeeId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    
    return AlertDialog(
      title: Text('Assign ${widget.shift.name}'),
      content: employeesAsync.when(
        data: (employees) => DropdownButtonFormField<int>(
          initialValue: _selectedEmployeeId,
          decoration: const InputDecoration(labelText: 'Employee', border: OutlineInputBorder()),
          items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
          onChanged: (v) => setState(() => _selectedEmployeeId = v),
        ),
        loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => const Text('Error loading employees'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selectedEmployeeId == null || _isLoading ? null : _assign,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _assign() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminOpsRepositoryProvider).assignShift(widget.shift.id, _selectedEmployeeId!);
      ref.invalidate(shiftsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Shift assigned'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
