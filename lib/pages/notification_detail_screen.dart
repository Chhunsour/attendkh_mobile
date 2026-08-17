import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  IconData _getTypeIcon(String type) {
    if (type.contains('announcement')) return Icons.campaign_rounded;
    if (type.contains('policy')) return Icons.policy_rounded;
    if (type.contains('document')) return Icons.description_rounded;
    if (type.contains('leave')) return Icons.event_available_rounded;
    if (type.contains('attendance') || type.contains('correction')) return Icons.fingerprint_rounded;
    if (type.contains('overtime')) return Icons.schedule_rounded;
    if (type.contains('expense')) return Icons.receipt_long_rounded;
    if (type.contains('payroll') || type.contains('salary') || type.contains('payslip')) return Icons.payments_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getTypeColor(String type) {
    if (type.contains('announcement')) return const Color(0xFFEF4444);
    if (type.contains('policy')) return const Color(0xFFEC4899);
    if (type.contains('document')) return const Color(0xFF14B8A6);
    if (type.contains('leave')) return const Color(0xFF3B82F6);
    if (type.contains('attendance') || type.contains('correction')) return const Color(0xFF6366F1);
    if (type.contains('overtime')) return const Color(0xFF8B5CF6);
    if (type.contains('expense')) return const Color(0xFFF59E0B);
    if (type.contains('payroll') || type.contains('salary') || type.contains('payslip')) return const Color(0xFF10B981);
    return AppColors.primary;
  }

  Map<String, dynamic>? _getAttachmentInfo(NotificationItem n) {
    final data = n.data ?? {};
    final type = n.type.toLowerCase();

    // 1. Daily Attendance Summary Report
    if (type.contains('attendance') && (type.contains('summary') || data['date'] != null)) {
      final date = data['date']?.toString() ?? (n.createdAt.isNotEmpty ? n.createdAt.split('T').first : 'report');
      return {
        'name': 'Daily_Attendance_Summary_$date.pdf',
        'type': 'Official Attendance PDF Report',
        'icon': Icons.picture_as_pdf_rounded,
        'color': const Color(0xFFE11D48),
      };
    }

    // 2. Payslip
    if (type.contains('payslip') || data['payslip_id'] != null) {
      final period = data['period']?.toString() ?? 'Payslip';
      return {
        'name': 'Payslip_$period.pdf',
        'type': 'Monthly Payslip Document (PDF)',
        'icon': Icons.picture_as_pdf_rounded,
        'color': const Color(0xFF10B981),
      };
    }

    // 3. Direct document / attachment / receipt
    final filePath = data['file_path'] ??
        data['document_path'] ??
        data['receipt_path'] ??
        data['pdf_path'] ??
        data['attachment'] ??
        data['document'] ??
        data['file_url'];

    if (filePath != null && filePath.toString().isNotEmpty) {
      final pathStr = filePath.toString();
      final filename = pathStr.split('/').last.split('?').first;
      final ext = filename.contains('.') ? filename.split('.').last.toUpperCase() : 'FILE';
      final isPdf = ext == 'PDF';
      final isImage = ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(ext);

      return {
        'name': filename.isNotEmpty ? filename : 'Attached_Document.$ext',
        'type': '$ext Attachment',
        'icon': isPdf
            ? Icons.picture_as_pdf_rounded
            : (isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded),
        'color': isPdf
            ? const Color(0xFFE11D48)
            : (isImage ? const Color(0xFF8B5CF6) : AppColors.primary),
      };
    }

    return null;
  }

  Future<void> _handleDownload(BuildContext context, NotificationItem n) async {
    try {
      final baseUrl = DioClient.instance.options.baseUrl.replaceAll('/api/v1', '');
      final downloadUrl = '$baseUrl/company/notifications/${n.id}/download-file';
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = notification;
    final typeIcon = _getTypeIcon(n.type);
    final typeColor = _getTypeColor(n.type);
    final attachment = _getAttachmentInfo(n);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey800),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.grey200.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 15, color: typeColor),
                            const SizedBox(width: 6),
                            Text(
                              n.type.replaceAll('.', ' ').replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatDateTime(n.createdAt),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.grey500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.grey200),
                  const SizedBox(height: 16),

                  // Body
                  if (n.body != null && n.body!.isNotEmpty)
                    Text(
                      n.body!,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppColors.grey800,
                        height: 1.6,
                      ),
                    )
                  else
                    const Text(
                      'No additional details provided.',
                      style: TextStyle(fontSize: 13, color: AppColors.grey400, fontStyle: FontStyle.italic),
                    ),

                  // File Attachment Box if available
                  if (attachment != null) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'ATTACHED DOCUMENT',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (attachment['color'] as Color).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (attachment['color'] as Color).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (attachment['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              attachment['icon'] as IconData,
                              color: attachment['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.grey900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  attachment['type'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleDownload(context, n),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Open', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
