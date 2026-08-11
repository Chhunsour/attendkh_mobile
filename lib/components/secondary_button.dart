import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

/// Full-width outlined secondary button with rounded pill shape.
///
/// Matches login-screen spec:
/// - Height: 55
/// - Border radius: 28
/// - Blue (AppColors.primary) border, white background
/// - Bold text
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  static const _height = 55.0;
  static const _radius = 18.0;
  static const _borderColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _borderColor,
          side: const BorderSide(color: _borderColor, width: 1.5),
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            
          ),
        ),
        child: Text(label),
      ),
    );
  }
}