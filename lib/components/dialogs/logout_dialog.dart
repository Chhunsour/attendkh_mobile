import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

/// Confirms sign-out, then clears the session.
///
/// Uses the platform alert (UIAlertController on iOS, Material 3 dialog on
/// Android) rather than a bespoke card: Apple's HIG asks destructive
/// confirmations to be a standard alert with a plain destructive action and
/// Cancel as the preferred button — not a large filled red target that is the
/// easiest thing on screen to hit by accident.
Future<void> showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog.adaptive(
      title: Text('${l10n.logOut}?'),
      content: Text(l10n.logoutConfirmationDesc),
      actions: [
        _adaptiveAction(
          ctx,
          label: l10n.cancel,
          isDefault: true,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        _adaptiveAction(
          ctx,
          label: l10n.logOut,
          isDestructive: true,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // The authProvider clears state and the router redirects to login.
    await ref.read(authProvider.notifier).logout();
  }
}

Widget _adaptiveAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  bool isDefault = false,
  bool isDestructive = false,
}) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDefaultAction: isDefault,
        isDestructiveAction: isDestructive,
        child: Text(label),
      );
    default:
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isDestructive ? AppColors.danger : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isDefault ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      );
  }
}
