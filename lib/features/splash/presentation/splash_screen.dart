import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.checkAuthStatus();

    if (!mounted) return;

    final isAuth = ref.read(isAuthenticatedProvider);
    if (isAuth) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(100),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'MPG',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MPG GARAGE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'HR Management System',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(179),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary.withAlpha(204),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}