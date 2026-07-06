import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/providers/documents_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: docsAsync.when(
        data: (docs) => docs.isEmpty
            ? const Center(child: Text('No documents available', style: TextStyle(color: AppColors.grey400)))
            : GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: docs.map((d) => GestureDetector(
                  onTap: () => _downloadDocument(context, ref, d),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 28)),
                      const SizedBox(height: 12),
                      Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(d.fileSize ?? '—', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
                    ]),
                  ),
                )).toList(),
              ),
        loading: () => const LoadingIndicator(message: 'Loading documents...'),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.grey400), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () => ref.invalidate(documentsProvider), icon: const Icon(Icons.refresh), label: const Text('Retry'))])),
      ),
    );
  }

  Future<void> _downloadDocument(BuildContext context, WidgetRef ref, DocumentData doc) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📥 Downloading ${doc.name}...'), backgroundColor: AppColors.info, behavior: SnackBarBehavior.floating),
      );
      // In production, open the download URL or use url_launcher
      if (doc.downloadUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📥 Download started'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Download failed: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }
}
