import 'package:flutter/material.dart';
import 'size_config.dart';

/// Wraps a screen to auto-init [SizeConfig] on every build.
/// Use this as the top-level wrapper for each screen.
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return builder(context);
  }
}

/// A responsive SizedBox that uses scaled dimensions.
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const ResponsiveSizedBox({super.key, this.width, this.height, this.child});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return SizedBox(
      width: width?.w,
      height: height?.h,
      child: child,
    );
  }
}

/// A responsive padding widget.
class ResponsivePadding extends StatelessWidget {
  final double horizontal;
  final double vertical;
  final Widget child;

  const ResponsivePadding({
    super.key,
    this.horizontal = 16,
    this.vertical = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      ),
      child: child,
    );
  }
}

/// A responsive circular avatar/icon container.
class ResponsiveIconContainer extends StatelessWidget {
  final double size;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData icon;
  final double? iconSize;

  const ResponsiveIconContainer({
    super.key,
    required this.size,
    required this.radius,
    this.backgroundColor,
    this.iconColor,
    required this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius.r),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: (iconSize ?? size * 0.5).w,
      ),
    );
  }
}

/// A responsive card with scaled border radius and padding.
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? padding;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius.r),
        border: border,
        boxShadow: boxShadow,
      ),
      child: padding != null
          ? Padding(
              padding: EdgeInsets.all(padding!.w),
              child: child,
            )
          : child,
    );
  }
}
