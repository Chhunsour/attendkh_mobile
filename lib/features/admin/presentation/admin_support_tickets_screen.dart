import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminSupportTicketsScreen extends StatelessWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final statuses = ['open', 'in_progress', 'open', 'closed'];
          final statusColors = [AppColors.warning, AppColors.info, AppColors.warning, AppColors.success];
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
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: statusColors[index].withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.support, color: statusColors[index]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ticket #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('From Company ${index + 1}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColors[index].withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statuses[index].replaceAll('_', ' ').replaceAllMapped(
                      RegExp(r'\b\w'),
                      (m) => m.group(0)!.toUpperCase(),
                    ),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColors[index]),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ),
          );
        },
      ),
    );
  }
}