import 'package:flutter/material.dart';

/// Full-width primary button with rounded pill shape and press animation.
///
/// Matches login-screen spec:
/// - Height: 55
/// - Border radius: 28
/// - Background: #4F7DF3
/// - White bold text
/// - Button shadow (blue with low opacity)
/// - Scale-down animation on press
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  static const _height = 55.0;
  static const _radius = 18.0;
  static const _bgColor = Color(0xFF4F7DF3);
  static const _shadowColor = Color(0x4D4F7DF3); // ~30 % opacity

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: _shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              if (!widget.isLoading && widget.onPressed != null) {
                widget.onPressed!();
              }
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: ElevatedButton(
              onPressed: null, // gesture handled by GestureDetector above
              style: ElevatedButton.styleFrom(
                backgroundColor: _bgColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _bgColor.withAlpha(200),
                disabledForegroundColor: Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radius),
                ),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        key: ValueKey('label-${widget.label}'),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
