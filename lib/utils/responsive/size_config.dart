import 'package:flutter/material.dart';

/// Responsive sizing utility based on a 375pt design baseline (iPhone 13/14).
///
/// Usage:
///   SizeConfig.init(context);  // call once in build() before using extensions
///   16.w  → width-scaled pixels
///   16.h  → height-scaled pixels
///   14.sp → text-scaled pixels (min scale 0.82, max 1.35)
///   16.r  → radius-scaled pixels
class SizeConfig {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _pixelRatio;

  /// Design baseline width (iPhone 13/14 = 390pt, using 375 for broader compat)
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  /// Orientation-aware scale factor
  static late double _widthScale;
  static late double _heightScale;

  /// Min/max scaling to prevent extreme values on very small or very large screens
  static const double _minScale = 0.82;
  static const double _maxScale = 1.35;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final orientation = mq.orientation;

    _screenWidth = orientation == Orientation.landscape
        ? size.height
        : size.width;
    _screenHeight = orientation == Orientation.landscape
        ? size.width
        : size.height;
    _pixelRatio = mq.devicePixelRatio;

    _widthScale = (_screenWidth / _baseWidth).clamp(_minScale, _maxScale);
    _heightScale = (_screenHeight / _baseHeight).clamp(_minScale, _maxScale);
  }

  // ── Scale factors ─────────────────────────────────────────────────────────

  /// Width scale factor
  static double get w => _widthScale;

  /// Height scale factor
  static double get h => _heightScale;

  /// Text scale factor (uses width scale)
  static double get sp => _widthScale;

  /// Radius scale factor (uses width scale)
  static double get r => _widthScale;

  // ── Screen info ──────────────────────────────────────────────────────────

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static double get pixelRatio => _pixelRatio;

  /// True if screen width < 360pt (very small phones like iPhone SE)
  static bool get isSmallPhone => _screenWidth < 360;

  /// True if screen width >= 414pt (large phones like iPhone Plus/Pro Max)
  static bool get isLargePhone => _screenWidth >= 414;

  /// True if screen width >= 600pt (tablets)
  static bool get isTablet => _screenWidth >= 600;

  /// Number of grid columns based on screen width
  static int get gridColumns {
    if (_screenWidth < 360) return 1;
    if (_screenWidth < 600) return 2;
    if (_screenWidth < 900) return 3;
    return 4;
  }

  /// Responsive padding based on screen size
  static EdgeInsets get horizontalPadding {
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 32);
    if (isLargePhone) return const EdgeInsets.symmetric(horizontal: 20);
    return const EdgeInsets.symmetric(horizontal: 16);
  }
}

// ── Extension helpers for clean syntax ─────────────────────────────────────

/// Usage: `16.w` → scaled width, `16.h` → scaled height, `14.sp` → scaled text
extension ResponsiveDouble on double {
  /// Scaled width pixels (e.g. `16.w`)
  double get w => this * SizeConfig.w;

  /// Scaled height pixels (e.g. `16.h`)
  double get h => this * SizeConfig.h;

  /// Scaled text size (e.g. `14.sp`)
  double get sp => this * SizeConfig.sp;

  /// Scaled radius (e.g. `16.r`)
  double get r => this * SizeConfig.r;
}

/// Usage: `16.w` → scaled width (works with int literals like `16`)
extension ResponsiveInt on int {
  double get w => this * SizeConfig.w;
  double get h => this * SizeConfig.h;
  double get sp => this * SizeConfig.sp;
  double get r => this * SizeConfig.r;
}
