import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Reusable text field for auth screens.
///
/// Features:
/// - Rounded border (16 radius)
/// - Icon prefix
/// - Optional suffix (e.g. visibility toggle)
/// - Height ~56
/// - Light grey border, white/off-white fill
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
  });

  // ── Design token constants (matches login-screen spec) ──
  static const _borderRadius = 16.0;
  static const _height = 56.0;
  static const _borderColor = AppColors.grey200;
  static const _fillColor = AppColors.grey50;
  static const _textColor = AppColors.grey900;
  static const _hintColor = AppColors.grey400;
  static const _iconColor = AppColors.grey400;
  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofocus: autofocus,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          
          color: _textColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: const TextStyle(
            color: _hintColor,
            fontSize: 16,
            
          ),
          labelStyle: const TextStyle(
            color: _hintColor,
            fontSize: 14,
            
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: _iconColor, size: 22),
          suffixIcon: suffix,
          filled: true,
          fillColor: _fillColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: AppColors.danger, width: 2),
          ),
        ),
      ),
    );
  }
}