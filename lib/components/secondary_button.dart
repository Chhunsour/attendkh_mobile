import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';

/// Full-width outlined secondary button with rounded pill shape.
///
/// Matches login-screen spec:
/// - Height: 55
/// - Border radius: 28
/// - Blue (AppColors.primary) border, white background
/// - Bold text
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;
  static const _height = 55.0;
  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF3B82F6) : AppColors.primary;
    final textColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;
    final bgColor = isDark ? const Color(0x183B82F6) : Colors.white;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: Listener(
          onPointerDown: (_) => setState(() => _isPressed = true),
          onPointerUp: (_) => setState(() => _isPressed = false),
          onPointerCancel: (_) => setState(() => _isPressed = false),
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: borderColor, width: 1.5),
              backgroundColor: bgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
