import 'package:flutter/material.dart';
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
    if (type.contains('attendance') || type.contains('correction')) return Icons.fingerprint_rounded;
    if (type.contains('overtime')) return Icons.schedule_rounded;
    if (type.contains('expense')) return Icons.receipt_long_rounded;
    if (type.contains('payroll') || type.contains('salary')) return Icons.payments_rounded;
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
    if (type.contains('payroll') || type.contains('salary')) return const Color(0xFF10B981);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = notification;
    final typeIcon = _getTypeIcon(n.type);
    final typeColor = _getTypeColor(n.type);

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
                              n.type.replaceAll('.', ' ').toUpperCase(),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
