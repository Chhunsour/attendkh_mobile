import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpg_hr_mobile_app/services/documents_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/logger/app_logger.dart';

final employeeDocumentsProvider = FutureProvider.autoDispose<List<DocumentData>>((ref) async {
  final repo = DocumentsRepository();
  return repo.getEmployeeDocuments();
});

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType.contains('image/')) return Icons.image_outlined;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel') || mimeType.contains('csv')) return Icons.table_chart_outlined;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description_outlined;
    if (mimeType.contains('zip') || mimeType.contains('archive') || mimeType.contains('rar')) return Icons.archive_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _getIconColor(String? mimeType) {
    if (mimeType == null) return AppColors.grey500;
    if (mimeType.contains('image/')) return Colors.blue;
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel') || mimeType.contains('csv')) return Colors.green;
    if (mimeType.contains('word') || mimeType.contains('document')) return Colors.blue.shade700;
    if (mimeType.contains('zip') || mimeType.contains('archive') || mimeType.contains('rar')) return Colors.orange;
    return AppColors.grey500;
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 Bytes';
    const k = 1024;
    final sizes = ['Bytes', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= k && i < sizes.length - 1) {
      size /= k;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${sizes[i]}';
  }

  Future<void> _downloadFile(BuildContext context, DocumentData doc) async {
    if (doc.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download URL is not available.')));
      return;
    }
    try {
      final uri = Uri.parse(doc.downloadUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch url';
      }
    } catch (e) {
      AppLogger.e('Failed to download document', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download document: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(employeeDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Company Documents'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (documents) {
          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined, size: 64, color: AppColors.grey300),
                  SizedBox(height: 16),
                  Text('No documents available', style: TextStyle(color: AppColors.grey600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getIconColor(doc.mimeType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getFileIcon(doc.mimeType), color: _getIconColor(doc.mimeType), size: 28),
                  ),
                  title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (doc.description != null && doc.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(doc.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.grey600)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4)),
                            child: Text(_formatBytes(doc.fileSize), style: const TextStyle(fontSize: 12, color: AppColors.grey700)),
                          ),
                          if (doc.department != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(doc.department!.name, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _downloadFile(context, doc),
                    icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryLight),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
