import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/providers/auth_provider.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import 'package:attendkh/utils/router/app_router.dart';

/// Shows a modern, premium sign-out confirmation dialog.
Future<void> showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? AppColors.borderDark
              : AppColors.border(ctx),
        ),
      ),
      icon: Container(
        width: 58,
        height: 58,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.logout_rounded,
          color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          size: 28,
        ),
      ),
      title: Text(
        '${l10n.logOut}?',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
      ),
      content: Text(
        l10n.logoutConfirmationDesc,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: isDark ? AppColors.grey400 : AppColors.grey600,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.grey700,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border(ctx)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: AppColors.danger.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: Text(
                    l10n.logOut,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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

  if (confirmed == true) {
    if (context.mounted) {
      // Show clean centered loading spinner
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black38,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.5,
            ),
          ),
        ),
      );
    }

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {}

    if (context.mounted) {
      context.go(AppRoutes.login);
    } else {
      rootNavigatorKey.currentContext?.go(AppRoutes.login);
    }
  }
}
