import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';

/// A generic "More" screen that displays secondary navigation items in a grid.
class MoreScreen extends ConsumerWidget {
  final String title;
  final List<MoreItem> items;
  final bool showLogout;

  const MoreScreen({
    super.key,
    required this.title,
    required this.items,
    this.showLogout = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              ...items.map((item) => _buildItem(context, item)),
              if (showLogout)
                _buildItem(
                  context,
                  MoreItem(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    color: AppColors.danger,
                    onTap: () => showLogoutConfirmation(context, ref),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, MoreItem item) {
    return InkWell(
      onTap: item.onTap ?? () => context.push(item.routePath!),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Describes a single item in the "More" grid.
class MoreItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? routePath;
  final VoidCallback? onTap;

  const MoreItem({
    required this.title,
    required this.icon,
    required this.color,
    this.routePath,
    this.onTap,
  });
}
