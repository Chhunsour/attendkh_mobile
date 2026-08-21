import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/fcm_service.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Staggered entrance, played once.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// The radar sweep. It is also the loading indicator — there is no second
  /// spinner, because two things saying "wait" is one thing too many.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final Animation<double> _rings = _curve(0.00, 0.75, Curves.easeOutCubic);
  late final Animation<double> _mark = _curve(0.05, 0.60, Curves.easeOutCubic);
  late final Animation<double> _word = _curve(0.30, 0.75, Curves.easeOutCubic);
  late final Animation<double> _tag = _curve(0.42, 0.85, Curves.easeOutCubic);
  late final Animation<double> _foot = _curve(0.60, 1.00, Curves.easeOut);

  Animation<double> _curve(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.instance.init();
    });
    _intro.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    try {
      await ref.read(authProvider.notifier).checkAuthStatus();
    } catch (_) {}

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (authState.isSuperAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else if (authState.isCompanyAdmin) {
        context.go(AppRoutes.companyAdmin);
      } else {
        context.go(AppRoutes.main);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _sweep.dispose();
    super.dispose();
  }

  /// Fade plus a short rise. Splash copy that slides up a few pixels settles;
  /// copy that scales or bounces draws attention to itself.
  Widget _rise(Animation<double> anim, Widget child, {double from = 14}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, from * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF061634),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A single light source: brand blue at the upper left falling away
          // to near-black. No second hue, no floating colour blobs.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2A80), Color(0xFF07143A), Color(0xFF050F2A)],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
          ),
          // Vignette, so the eye lands on the mark rather than the corners.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.28),
                radius: 1.0,
                colors: [
                  AppColors.primary.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),

                // The geofence rings are the illustration: this app decides
                // whether you are inside a radius, so the radius is the image.
                SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _rings,
                        builder: (context, _) => CustomPaint(
                          size: const Size.square(320),
                          painter: _RingsPainter(progress: _rings.value),
                        ),
                      ),
                      RotationTransition(
                        turns: _sweep,
                        child: FadeTransition(
                          opacity: _rings,
                          child: const CustomPaint(
                            size: Size.square(320),
                            painter: _SweepPainter(),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.9,
                          end: 1.0,
                        ).animate(_mark),
                        child: FadeTransition(
                          opacity: _mark,
                          child: _buildMark(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                _rise(
                  _word,
                  const Text(
                    'AttendKH',
                    style: TextStyle(
                      fontSize: 31,
                      // Tight and medium-heavy. The old w900 at +2.5 tracking
                      // was shouting.
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _rise(
                  _tag,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Text(
                      l10n.smartAttendanceSystem,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        // No negative tracking here — the Khmer tagline needs
                        // its natural spacing.
                        color: Colors.white.withValues(alpha: 0.60),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 6),

                _rise(
                  _foot,
                  Text(
                    l10n.poweredByAttendKH.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  from: 8,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The logo in a thin collar. Rendered here rather than via [AppLogo] so the
  /// splash does not inherit that widget's heavy halo — the rings already do
  /// the work that halo was attempting.
  Widget _buildMark() {
    const double size = 104;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/attendkh_logo.png',
          fit: BoxFit.cover,
          cacheWidth: 312,
          cacheHeight: 312,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppColors.primary,
            child: Center(
              child: Text(
                'AK',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Concentric geofence rings, drawn from the inside out as the intro plays.
/// Every second ring is dashed, so the set reads as a measured radius rather
/// than as decoration.
class _RingsPainter extends CustomPainter {
  final double progress;

  const _RingsPainter({required this.progress});

  static const _radii = <double>[66, 96, 124, 150];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (int i = 0; i < _radii.length; i++) {
      // Each ring waits for the one inside it.
      final t = ((progress - i * 0.12) / 0.55).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: (0.20 - i * 0.04) * t);

      final r = _radii[i] * (0.94 + 0.06 * t);
      if (i.isOdd) {
        _dashedCircle(canvas, center, r, paint);
      } else {
        canvas.drawCircle(center, r, paint);
      }
    }
  }

  void _dashedCircle(Canvas canvas, Offset center, double r, Paint paint) {
    const dash = 0.045; // radians drawn
    const gap = 0.030; // radians skipped
    final rect = Rect.fromCircle(center: center, radius: r);
    for (double a = 0; a < math.pi * 2; a += dash + gap) {
      canvas.drawArc(rect, a, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.progress != progress;
}

/// The sweep: a comet arc riding the outer ring with a bright head, the way a
/// radar trace or a second hand reads. Rotated by its parent.
class _SweepPainter extends CustomPainter {
  const _SweepPainter();

  static const _radius = 150.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: _radius);

    // Tail fades out behind the head, which sits at angle 0.
    final tail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi * 0.5,
        endAngle: 0,
        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.85)],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi * 0.5, math.pi * 0.5, false, tail);

    // The head: the detail that makes it read as an instrument.
    final head = Offset(center.dx + _radius, center.dy);
    canvas.drawCircle(head, 8, Paint()..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawCircle(head, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) => false;
}
