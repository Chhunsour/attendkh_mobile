import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/announcements/data/announcements_repository.dart';
import 'package:mpg_hr_mobile_app/features/announcements/presentation/announcements_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        data: (announcements) => announcements.isEmpty
            ? const Center(child: Text('No announcements', style: TextStyle(color: AppColors.grey400)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: announcements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = announcements[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: a.isImportant ? AppColors.dangerLight : AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.isImportant ? 'Important' : 'General',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: a.isImportant ? AppColors.danger : AppColors.secondary),
                              ),
                            ),
                            const Spacer(),
                            Text(a.createdAt, style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(a.content, style: TextStyle(fontSize: 13, color: AppColors.grey500), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const LoadingIndicator(message: 'Loading...'),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.grey400), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => ref.invalidate(announcementsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))])),
      ),
    );
  }
}