import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/utils/theme/theme.dart';

class AssetSharedWidgets {
  static Color conditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'good':
        return AppColors.info;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.deepOrange;
      case 'damaged':
        return AppColors.danger;
      default:
        return AppColors.grey500;
    }
  }

  static Color conditionBgColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green.shade50;
      case 'good':
        return Colors.blue.shade50;
      case 'fair':
        return Colors.orange.shade50;
      case 'poor':
        return Colors.deepOrange.shade50;
      case 'damaged':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'assigned':
        return AppColors.info;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return AppColors.grey500;
      default:
        return AppColors.grey500;
    }
  }

  static IconData categoryIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('laptop') ||
        cat.contains('computer') ||
        cat.contains('macbook')) {
      return Icons.laptop;
    }
    if (cat.contains('phone') || cat.contains('mobile')) {
      return Icons.smartphone;
    }
    if (cat.contains('monitor') || cat.contains('display')) {
      return Icons.monitor;
    }
    if (cat.contains('vehicle') ||
        cat.contains('car') ||
        cat.contains('truck')) {
      return Icons.local_shipping;
    }
    return Icons.inventory_2;
  }

  static Widget buildConditionBadge(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: conditionBgColor(condition),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: conditionColor(condition).withAlpha(77)),
      ),
      child: Text(
        condition.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: conditionColor(condition),
        ),
      ),
    );
  }

  static Widget buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor(status).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.isEmpty
            ? ''
            : status.substring(0, 1).toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: statusColor(status),
        ),
      ),
    );
  }

  static Widget buildEmployeeAvatar({
    String? photoUrl,
    required String name,
    double size = 36,
  }) {
    final cleanName = name.trim();
    final initial = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '?';
    final validPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(color: AppColors.primary.withAlpha(35)),
      ),
      child: validPhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 3),
              child: CachedNetworkImage(
                imageUrl: photoUrl.startsWith('http')
                    ? photoUrl
                    : '${DioClient.storageUrl}/${photoUrl.startsWith('/') ? photoUrl.substring(1) : photoUrl}',
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                memCacheHeight: 120,
                placeholder: (_, _) => Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.42,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}
