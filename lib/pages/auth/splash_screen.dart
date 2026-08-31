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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FcmService.instance.consumePendingNotification();
      });
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
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Ambient Midnight Background ──
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0F1D),
                  Color(0xFF0F172A),
                  Color(0xFF0D1B3E),
                  Color(0xFF070B14),
                ],
                stops: [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),

          // ── Glowing ambient light accents ──
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.14),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),

                // Geofence rings & radar sweep
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
                          begin: 0.88,
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

                const SizedBox(height: 28),

                _rise(
                  _word,
                  const Text(
                    'AttendKH',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

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
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 6),

                _rise(
                  _foot,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.poweredByAttendKH.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                  from: 8,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The logo in a glowing frosted collar.
  Widget _buildMark() {
    const double size = 104;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
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

/// Concentric geofence rings, drawn with subtle primary tints.
class _RingsPainter extends CustomPainter {
  final double progress;

  const _RingsPainter({required this.progress});

  static const _radii = <double>[66, 96, 124, 150];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (int i = 0; i < _radii.length; i++) {
      final t = ((progress - i * 0.12) / 0.55).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF60A5FA).withValues(alpha: (0.28 - i * 0.05) * t);

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

/// The sweep: vibrant cyan/blue radar trace with glowing instrument head.
class _SweepPainter extends CustomPainter {
  const _SweepPainter();

  static const _radius = 150.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: _radius);

    // Tail fades out behind the head with cyan/indigo glow
    final tail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi * 0.5,
        endAngle: 0,
        colors: [
          Colors.transparent,
          Color(0xFF38BDF8),
        ],
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi * 0.5, math.pi * 0.5, false, tail);

    // Instrument head: cyan glow dot
    final head = Offset(center.dx + _radius, center.dy);
    canvas.drawCircle(
      head,
      9,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      head,
      3.5,
      Paint()..color = const Color(0xFFE0F2FE),
    );
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) => false;
}
