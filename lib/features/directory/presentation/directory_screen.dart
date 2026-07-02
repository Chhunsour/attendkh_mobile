import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/directory/presentation/directory_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Directory')),
      body: employeesAsync.when(
        data: (employees) => employees.isEmpty
            ? const Center(child: Text('No employees', style: TextStyle(color: AppColors.grey400)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: employees.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = employees[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])),
                          child: Center(child: Text(e.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('${e.position ?? 'Employee'}${e.department != null ? ' • ${e.department}' : ''}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                          ]),
                        ),
                        if (e.email != null) IconButton(icon: const Icon(Icons.email_outlined, color: AppColors.secondary), onPressed: () {}),
                        if (e.phone != null) IconButton(icon: const Icon(Icons.phone_outlined, color: AppColors.primary), onPressed: () {}),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const LoadingIndicator(message: 'Loading directory...'),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.grey400), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => ref.invalidate(employeesProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))])),
      ),
    );
  }
}