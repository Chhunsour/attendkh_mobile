import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Announcements'),
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
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.successLight : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        index == 0 ? 'Published' : 'Draft',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: index == 0 ? AppColors.success : AppColors.warning),
                      ),
                    ),
                    const Spacer(),
                    Text('${index + 1} Jul 2026', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  index == 0 ? 'System Maintenance Notice' : index == 1 ? 'New Feature Release' : 'Holiday Schedule',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Platform-wide announcement for all companies.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}