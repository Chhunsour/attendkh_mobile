import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Shows an Apple Guideline 5.1.1(v) compliant Account Deletion confirmation dialog.
Future<void> showDeleteAccountConfirmation(
  BuildContext context,
  WidgetRef ref,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.danger.withValues(alpha: isDark ? 0.35 : 0.20),
        ),
      ),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.danger,
          size: 32,
        ),
      ),
      title: Text(
        'Delete Account?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
      ),
      content: Text(
        'This will permanently delete your personal account and sign you out on every device. If you are an employee, statutory attendance and payroll records are kept but anonymized. This action cannot be undone.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: isDark ? AppColors.grey400 : AppColors.grey600,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.grey700,
                    side: BorderSide(color: AppColors.border(ctx)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete My Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    // Show deleting indicator overlay
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Deleting account and clearing data...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.grey900,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref.read(authProvider.notifier).deleteAccount();
    } catch (e) {
      // Deletion failed — the session is untouched, keep the user signed in.
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to delete account. Please try again or contact support.',
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted.'),
            backgroundColor: AppColors.grey900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.go(AppRoutes.login); // go_router: replaces the whole stack
    }
  }
}
