import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final actions = ['login', 'update_company', 'create_user', 'delete_announcement', 'update_settings', 'suspend_company', 'approve_ticket', 'login'];
          final users = ['super_admin', 'super_admin', 'admin@co1', 'super_admin', 'super_admin', 'super_admin', 'super_admin', 'admin@co3'];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: actions[index] == 'suspend_company' || actions[index] == 'delete_announcement'
                        ? AppColors.dangerLight
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    actions[index].contains('delete') || actions[index].contains('suspend')
                        ? Icons.warning_amber
                        : Icons.check_circle_outline,
                    size: 16,
                    color: actions[index].contains('delete') || actions[index].contains('suspend')
                        ? AppColors.danger
                        : AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actions[index].replaceAll('_', ' ').replaceAllMapped(
                          RegExp(r'\b\w'),
                          (m) => m.group(0)!.toUpperCase(),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'By ${users[index]} • ${index + 1}h ago',
                        style: TextStyle(fontSize: 11, color: AppColors.grey400),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.grey400),
              ],
            ),
          );
        },
      ),
    );
  }
}