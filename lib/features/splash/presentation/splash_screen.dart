import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/core/utils/responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _animController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // Trigger auth check — the GoRouter redirect will navigate automatically
    // when isLoading flips to false (see app_router.dart refreshListenable).
    await ref.read(authProvider.notifier).checkAuthStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0D1B3E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo image from assets ──
                    Container(
                      width: r.w(120),
                      height: r.w(120),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r.w(28)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(120),
                            blurRadius: r.w(40),
                            spreadRadius: r.w(4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(r.w(28)),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SizedBox(height: r.h(28)),

                    // ── App name ──
                    Text(
                      'MPG HR',
                      style: TextStyle(
                        fontSize: r.sp(32),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: r.w(4),
                        fontFamily: 'Inter',
                      ),
                    ),

                    SizedBox(height: r.h(8)),

                    Text(
                      'HR Management System',
                      style: TextStyle(
                        fontSize: r.sp(14),
                        color: Colors.white.withAlpha(179),
                        fontWeight: FontWeight.w400,
                        letterSpacing: r.w(0.5),
                        fontFamily: 'Inter',
                      ),
                    ),

                    SizedBox(height: r.h(64)),

                    // ── Loading indicator ──
                    SizedBox(
                      width: r.w(24),
                      height: r.w(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withAlpha(200),
                        ),
                      ),
                    ),

                    SizedBox(height: r.h(16)),

                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: r.sp(12),
                        color: Colors.white.withAlpha(100),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}