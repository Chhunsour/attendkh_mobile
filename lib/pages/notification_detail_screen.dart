import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/notifications_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({super.key, required this.notification});

  static const _typeIcons = {
    'announcement.published': Icons.campaign_rounded,
    'policy.published': Icons.menu_book_rounded,
    'document.uploaded': Icons.description_rounded,
  };

  static const _typeColors = {
    'announcement.published': AppColors.primary,
    'policy.published': Color(0xFF9333EA),
    'document.uploaded': AppColors.primary,
  };

  static const _typeBgs = {
    'announcement.published': AppColors.primaryLight,
    'policy.published': Color(0xFFF3E8FF),
    'document.uploaded': AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = notification;
    final typeIcon = _typeIcons[n.type] ?? Icons.notifications_outlined;
    final typeColor = _typeColors[n.type] ?? AppColors.grey500;
    final typeBg = _typeBgs[n.type] ?? AppColors.grey100;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey800),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 16, color: typeColor),
                      const SizedBox(width: 6),
                      Text(
                        n.type.replaceAll('.', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDateTime(n.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              n.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            const Divider(color: AppColors.grey200, height: 1),
            const SizedBox(height: 16),

            // Message body
            Text(
              n.body ?? l10n.noAdditionalDetails,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.grey700,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.grey300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.closeBtn,
                        style: const TextStyle(
                          color: AppColors.grey700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
