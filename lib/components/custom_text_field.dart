import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';

/// Reusable text field with full Light & Dark mode adaptation.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;

  /// iOS/Android password-manager integration (see [AutofillHints]).
  final Iterable<String>? autofillHints;

  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    required this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.autofillHints,
  });

  static const _borderRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark ? AppColors.surfaceDarkElevated : AppColors.grey50;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.grey900;
    final hintColor = isDark ? AppColors.grey500 : AppColors.grey400;
    final iconColor = isDark ? const Color(0xFF94A3B8) : AppColors.grey500;

    // ponytail: no fixed height — the field grows with Dynamic Type / large
    // accessibility text sizes instead of clipping (Apple HIG: support Dynamic Type).
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      enabled: enabled,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autofillHints: autofillHints,
      // Never send secrets to the keyboard's learning dictionary / suggestion strip.
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      textCapitalization: TextCapitalization.none,
      style: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(prefixIcon, color: iconColor, size: 21),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.danger,
        ),
      ),
    );
  }
}
