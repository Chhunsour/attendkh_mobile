import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminCompaniesScreen extends StatelessWidget {
  const AdminCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.business, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Company ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('admin@company${index + 1}.com', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: index == 4 ? AppColors.dangerLight : AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    index == 4 ? 'Suspended' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: index == 4 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ),
          );
        },
      ),
    );
  }
}