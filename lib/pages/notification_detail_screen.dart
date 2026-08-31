import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  IconData _getTypeIcon(String type) {
    if (type.contains('announcement')) return Icons.campaign_rounded;
    if (type.contains('policy')) return Icons.policy_rounded;
    if (type.contains('document')) return Icons.description_rounded;
    if (type.contains('leave')) return Icons.event_available_rounded;
    if (type.contains('attendance') || type.contains('correction')) {
      return Icons.fingerprint_rounded;
    }
    if (type.contains('overtime')) return Icons.schedule_rounded;
    if (type.contains('expense')) return Icons.receipt_long_rounded;
    if (type.contains('payroll') ||
        type.contains('salary') ||
        type.contains('payslip')) {
      return Icons.payments_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getTypeColor(String type) {
    if (type.contains('announcement')) return const Color(0xFFEF4444);
    if (type.contains('policy')) return const Color(0xFFEC4899);
    if (type.contains('document')) return const Color(0xFF14B8A6);
    if (type.contains('leave')) return const Color(0xFF3B82F6);
    if (type.contains('attendance') || type.contains('correction')) {
      return const Color(0xFF6366F1);
    }
    if (type.contains('overtime')) return const Color(0xFF8B5CF6);
    if (type.contains('expense')) return const Color(0xFFF59E0B);
    if (type.contains('payroll') ||
        type.contains('salary') ||
        type.contains('payslip')) {
      return const Color(0xFF10B981);
    }
    return AppColors.primary;
  }

  Map<String, dynamic>? _getAttachmentInfo(NotificationItem n) {
    final data = n.data ?? {};
    final type = n.type.toLowerCase();

    // 1. Daily Attendance Summary Report
    if (type.contains('attendance') &&
        (type.contains('summary') || data['date'] != null)) {
      final date = data['date']?.toString() ??
          (n.createdAt.isNotEmpty ? n.createdAt.split('T').first : 'report');
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
      final ext = filename.contains('.')
          ? filename.split('.').last.toUpperCase()
          : 'FILE';
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
      final attachment = _getAttachmentInfo(n);
      final filename = attachment?['name'] ?? 'attachment_${n.id}.pdf';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Downloading $filename...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$filename';

      final repo = NotificationsRepository();
      await repo.downloadAttachment(n.id, savePath);

      if (context.mounted) {
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final n = notification;
    final typeIcon = _getTypeIcon(n.type);
    final typeColor = _getTypeColor(n.type);
    final attachment = _getAttachmentInfo(n);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ── Royal Blue Curved Hero Header ──
            _buildHeroHeader(context, l10n),

            // ── Body Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Notification Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.20 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
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
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(
                                      alpha: isDark ? 0.20 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(typeIcon, size: 15, color: typeColor),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          n.type
                                              .replaceAll('.', ' ')
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: typeColor,
                                            letterSpacing: 0.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDateTime(n.createdAt),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.grey900,
                              letterSpacing: -0.3,
                            ),
                          ),

                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 16),

                          // Body
                          if (n.body != null && n.body!.isNotEmpty)
                            Text(
                              n.body!,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : AppColors.grey800,
                                height: 1.65,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'No additional details provided.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.grey500
                                    : AppColors.grey400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                          // File Attachment Box if available
                          if (attachment != null) ...[
                            const SizedBox(height: 20),
                            Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'ATTACHED DOCUMENT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.grey400
                                        : AppColors.grey600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Material(
                              color: (attachment['color'] as Color).withValues(
                                alpha: isDark ? 0.12 : 0.06,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => _handleDownload(context, n),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (attachment['color'] as Color)
                                          .withValues(
                                        alpha: isDark ? 0.35 : 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (attachment['color'] as Color)
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          attachment['icon'] as IconData,
                                          color: attachment['color'] as Color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              attachment['name'] as String,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.grey900,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              attachment['type'] as String,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? AppColors.grey400
                                                    : AppColors.grey500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.download_rounded,
                                        size: 20,
                                        color: isDark
                                            ? AppColors.grey300
                                            : AppColors.grey600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8),
            Color(0xFF0052FF),
            Color(0xFF1E6BFF),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.notifications,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
