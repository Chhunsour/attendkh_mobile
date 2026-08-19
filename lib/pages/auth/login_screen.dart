import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';
import 'package:mpg_hr_mobile_app/components/secondary_button.dart';
import 'package:mpg_hr_mobile_app/components/language_switch_button.dart';
import 'package:mpg_hr_mobile_app/components/theme_switch_button.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ── Animation controllers ──
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login handler ──
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.login(
      login: _loginController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // GoRouter redirect handles navigation automatically
    } else if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFF071228),
      body: Stack(
        children: [
          // ── Layer 1: Modern Tech Gradient Background ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF061124),
                    Color(0xFF092055),
                    Color(0xFF0038B8),
                    Color(0xFF02132B),
                  ],
                  stops: [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // ── Layer 2: Ambient Glowing Light Orbs ──
          Positioned(
            top: -size.width * 0.2,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(50),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.22,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withAlpha(35),
              ),
            ),
          ),

          // ── Layer 3: Top Navigation Bar with Language & Theme Switchers ──
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    ThemeSwitchButton(isDarkHeader: true),
                    SizedBox(width: 8),
                    LanguageSwitchButton(isDark: true),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 4: Main Content Layout ──
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top Header Branding
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Glowing Logo
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withAlpha(120),
                                            blurRadius: 30,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: AppLogo(size: 80),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'AttendKH',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.smartAttendanceSystem,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withAlpha(200),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom Form Card
                          Expanded(
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(36),
                                    topRight: Radius.circular(36),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(70),
                                      blurRadius: 30,
                                      offset: const Offset(0, -10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(36),
                                    topRight: Radius.circular(36),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Attendance Readiness Badge
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withAlpha(20),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary.withAlpha(40),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('📍', style: TextStyle(fontSize: 12)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    l10n.gpsAttendanceReady,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark
                                                          ? const Color(0xFF93C5FD)
                                                          : AppColors.primaryDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // Title
                                          Text(
                                            l10n.welcomeBack,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.grey900,
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Identity Input (Phone / Email / Employee ID)
                                          CustomTextField(
                                            controller: _loginController,
                                            hintText: l10n.loginIdentityHint,
                                            labelText: l10n.loginIdentityLabel,
                                            prefixIcon: Icons.badge_outlined,
                                            keyboardType: TextInputType.text,
                                            validator: (v) =>
                                                v == null || v.trim().isEmpty
                                                    ? l10n.fieldRequired
                                                    : null,
                                          ),
                                          const SizedBox(height: 16),

                                          // Password Input
                                          CustomTextField(
                                            controller: _passwordController,
                                            hintText: l10n.enterYourPassword,
                                            labelText: l10n.password,
                                            prefixIcon: Icons.lock_outline_rounded,
                                            obscureText: _obscurePassword,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) => _handleLogin(),
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppColors.grey400,
                                                size: 22,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword,
                                              ),
                                            ),
                                            validator: (v) =>
                                                v == null || v.isEmpty
                                                    ? l10n.passwordRequired
                                                    : null,
                                          ),
                                          const SizedBox(height: 22),

                                          // Sign In Button
                                          PrimaryButton(
                                            label: l10n.signIn,
                                            isLoading: authState.isLoading,
                                            onPressed: _handleLogin,
                                          ),
                                          const SizedBox(height: 16),

                                          // OR Divider
                                          _OrDivider(l10n: l10n),
                                          const SizedBox(height: 16),

                                          // Create Company Account Button
                                          SecondaryButton(
                                            label: l10n.createAccount,
                                            onPressed: () =>
                                                context.go(AppRoutes.register),
                                          ),
                                          const SizedBox(height: 16),

                                          // Cambodian HR Footer Note
                                          Text(
                                            l10n.cambodiaAttendanceTagline,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey500,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OR DIVIDER
// ══════════════════════════════════════════════════════════════════════════════
class _OrDivider extends StatelessWidget {
  final AppLocalizations l10n;
  const _OrDivider({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.or,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.grey400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border(context),
          ),
        ),
      ],
    );
  }
}