import 'package:flutter/material.dart';

/// Responsive utility — provides screen-size-aware sizing helpers.
/// Usage:
///   final r = Responsive(context);
///   r.w(16)   → 16% of screen width
///   r.h(10)   → 10% of screen height
///   r.sp(14)  → font size scaled to screen
///   r.isTablet → true if width >= 600
class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;

  // Base design dimensions (iPhone 14 Pro, 390x844)
  static const double _baseWidth = 390;
  static const double _baseHeight = 844;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    _width = size.width;
    _height = size.height;
  }

  /// Screen width
  double get screenWidth => _width;

  /// Screen height
  double get screenHeight => _height;

  /// Width as percentage (0-100)
  double wp(double percent) => _width * percent / 100;

  /// Height as percentage (0-100)
  double hp(double percent) => _height * percent / 100;

  /// Scale a design pixel value relative to base width (390px)
  double w(double px) => px * _width / _baseWidth;

  /// Scale a design pixel value relative to base height (844px)
  double h(double px) => px * _height / _baseHeight;

  /// Responsive font size — scales with screen width
  double sp(double fontSize) => fontSize * _width / _baseWidth;

  /// Responsive padding/margin (shorter alias for w())
  double r(double px) => w(px);

  /// Is tablet (width >= 600)
  bool get isTablet => _width >= 600;

  /// Is large phone (width >= 428, e.g. iPhone Plus)
  bool get isLargePhone => _width >= 428 && _width < 600;

  /// Is small phone (width < 360)
  bool get isSmallPhone => _width < 360;

  /// Safe horizontal padding
  double get horizontalPadding => isTablet ? wp(8) : w(20);

  /// Adaptive column count for grids
  int get gridColumns => isTablet ? 3 : 2;
}

/// Extension for quick access from BuildContext
extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive(this);
}
