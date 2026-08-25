import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/language_switch_button.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';
import 'package:mpg_hr_mobile_app/components/theme_switch_button.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://attendkh.com/privacy-policy';

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

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ponytail: client-side speed bump only; the server remains the real rate
  // limiter and account lockout authority.
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);
  int _failedAttempts = 0;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  bool get _isLocked => _lockSecondsLeft > 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _lockTimer?.cancel();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockout() {
    _failedAttempts = 0;
    setState(() => _lockSecondsLeft = _lockDuration.inSeconds);
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _lockSecondsLeft--);
      if (_lockSecondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;

    if (_isLocked) {
      _showError('${l10n.tooManyAttempts} ($_lockSecondsLeft s)');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    await ref
        .read(authProvider.notifier)
        .login(
          login: _loginController.text.trim(),
          // Whitespace can be part of a password, so never trim this value.
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      TextInput.finishAutofillContext();
      return;
    }

    if (authState.error != null) {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _startLockout();
        _showError(l10n.tooManyAttempts);
      } else {
        _showError(authState.error!);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0F1D),
              Color(0xFF0F172A),
              Color(0xFF0D1B3E),
              Color(0xFF070B14),
            ],
            stops: [0.0, 0.4, 0.75, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFFDBEAFE),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // ── Layer 1: Ambient Background ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: bgGradient),
              ),
            ),

            // ── Glowing ambient light accents ──
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),

            // ── Layer 2: Main Scrollable Content ──
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 720;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Top Bar (Controls)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Subtle badge — Flexible so it shrinks on narrow screens
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.08 : 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.12 : 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'HR & Attendance',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white70 : AppColors.primary,
                                              letterSpacing: 0.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Switches — compact mode hides text labels on small screens
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : AppColors.border(context),
                                    ),
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ThemeSwitchButton(isDarkHeader: isDark, compact: true),
                                      const SizedBox(width: 4),
                                      LanguageSwitchButton(isDark: isDark, compact: true),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isCompact ? 24 : 36),

                            // Brand Icon & Title
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildBrand(l10n, isDark, isCompact),
                            ),

                            SizedBox(height: isCompact ? 24 : 32),

                            // Floating Form Card
                            SlideTransition(
                              position: _slideAnim,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.border(context),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.35)
                                          : AppColors.primary.withValues(alpha: 0.08),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: _buildCardContent(
                                  l10n,
                                  isDark,
                                  authState,
                                  isCompact,
                                ),
                              ),
                            ),

                            const Spacer(),

                            const SizedBox(height: 16),

                            // Bottom Privacy link
                            Center(
                              child: TextButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse(_privacyPolicyUrl),
                                  mode: LaunchMode.inAppBrowserView,
                                ),
                                icon: Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                                ),
                                label: Text(
                                  l10n.privacyPolicy,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(44, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }

  Widget _buildBrand(AppLocalizations l10n, bool isDark, bool isCompact) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                  blurRadius: isCompact ? 18 : 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AppLogo(size: isCompact ? 60 : 70),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            'AttendKH',
            style: TextStyle(
              fontSize: isCompact ? 22 : 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.smartAttendanceSystem,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(
    AppLocalizations l10n,
    bool isDark,
    AuthState authState,
    bool isCompact,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        isCompact ? 22 : 26,
        22,
        isCompact ? 22 : 26,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcomeBack,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.grey900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.signInSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                ),
              ),
              SizedBox(height: isCompact ? 18 : 22),
              if (_isLocked) ...[
                _LockBanner(
                  message: l10n.tooManyAttempts,
                  secondsLeft: _lockSecondsLeft,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _loginController,
                hintText: l10n.loginIdentityHint,
                labelText: l10n.loginIdentityLabel,
                prefixIcon: Icons.badge_outlined,
                enabled: !authState.isLoading,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.fieldRequired
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                hintText: l10n.enterYourPassword,
                labelText: l10n.password,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                enabled: !authState.isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                autofillHints: const [AutofillHints.password],
                suffix: IconButton(
                  tooltip: _obscurePassword
                      ? l10n.showPassword
                      : l10n.hidePassword,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                    size: 21,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? l10n.passwordRequired
                    : null,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: _isLocked
                    ? '${l10n.signIn} ($_lockSecondsLeft s)'
                    : l10n.signIn,
                isLoading: authState.isLoading,
                onPressed: _isLocked ? null : _handleLogin,
              ),
              const SizedBox(height: 18),

              // Divider with clean text
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : AppColors.grey200,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.grey500 : AppColors.grey400,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : AppColors.grey200,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Register Company Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => context.go(AppRoutes.register),
                  icon: const Icon(Icons.business_rounded, size: 18),
                  label: Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.primary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockBanner extends StatelessWidget {
  final String message;
  final int secondsLeft;

  const _LockBanner({required this.message, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeBg(context, AppColors.danger),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            size: 20,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$message (${secondsLeft}s)',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.badgeText(context, AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
