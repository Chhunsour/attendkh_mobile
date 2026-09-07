import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';

/// Circular logo widget used on login / splash screens.
///
/// Displays the MPG logo image from assets inside a white-bordered circle
/// with a primary gradient background and a soft glow shadow.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120});

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withAlpha(120),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.04,
          ),
        ],
        border: Border.all(color: AppColors.surfaceLight, width: 3),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/attendkh_logo.png',
          fit: BoxFit.cover,
          cacheWidth: (size * 3).toInt(),
          cacheHeight: (size * 3).toInt(),
          errorBuilder: (_, _, _) => Center(
            child: Text(
              'AttendKH',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                letterSpacing: 1.5,
                
              ),
            ),
          ),
        ),
      ),
    );
  }
}