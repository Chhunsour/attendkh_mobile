import 'package:flutter/material.dart';

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
  static const _borderColor = Color(0xFFE5E5E5);
  static const _fillColor = Color(0xFFFAFAFA);
  static const _textColor = Color(0xFF222222);
  static const _hintColor = Color(0xFF9CA3AF);
  static const _iconColor = Color(0xFF9CA3AF);
  static const _primaryColor = Color(0xFF4F7DF3);

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
          fontFamily: 'Inter',
          color: _textColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: const TextStyle(
            color: _hintColor,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
          labelStyle: const TextStyle(
            color: _hintColor,
            fontSize: 14,
            fontFamily: 'Inter',
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
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }
}