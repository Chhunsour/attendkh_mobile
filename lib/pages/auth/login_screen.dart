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
import 'package:mpg_hr_mobile_app/services/auth_repository.dart';
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

  Future<void> _openForgotPassword() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(initialEmail: _loginController.text),
    );
    if (sent == true && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetLinkSent),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : const Color(0xFF071228),
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
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
            Positioned(
              top: -size.width * 0.2,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 700;
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: isCompact ? 66 : 79),
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildBrand(l10n, isCompact),
                            ),
                            SizedBox(height: isCompact ? 16 : 20),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
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
                                    child: _buildCardContent(
                                      l10n,
                                      isDark,
                                      authState,
                                      isCompact,
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBackButton(),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ThemeSwitchButton(isDarkHeader: true),
                        SizedBox(width: 8),
                        LanguageSwitchButton(isDark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand(AppLocalizations l10n, bool isCompact) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.48),
                  blurRadius: isCompact ? 18 : 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AppLogo(size: isCompact ? 64 : 72),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          const Text(
            'AttendKH',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.smartAttendanceSystem,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 22,
        ),
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
        24,
        isCompact ? 24 : 28,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
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
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.signInSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
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
                    color: AppColors.grey400,
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? l10n.passwordRequired
                    : null,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: authState.isLoading ? null : _openForgotPassword,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    foregroundColor: isDark
                        ? AppColors.primaryAccent
                        : AppColors.primary,
                  ),
                  child: Text(
                    l10n.forgotPassword,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              PrimaryButton(
                label: _isLocked
                    ? '${l10n.signIn} ($_lockSecondsLeft s)'
                    : l10n.signIn,
                isLoading: authState.isLoading,
                onPressed: _isLocked ? null : _handleLogin,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => context.go(AppRoutes.register),
                  icon: const Icon(Icons.apartment_rounded, size: 18),
                  label: Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: isDark
                        ? AppColors.primaryAccent
                        : AppColors.primary,
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(_privacyPolicyUrl),
                    mode: LaunchMode.inAppBrowserView,
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 15),
                  label: Text(
                    l10n.privacyPolicy,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 40),
                    foregroundColor: isDark
                        ? const Color(0xFF93C5FD)
                        : AppColors.primary,
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

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail.contains('@') ? widget.initialEmail.trim() : '',
  );
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await AuthRepository().forgotPassword(_emailController.text.trim());
    } catch (_) {
      // Keep the response neutral so account existence is not disclosed.
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.resetPasswordTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.resetPasswordDesc,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _emailController,
                  labelText: l10n.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_sending,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return l10n.emailRequired;
                    if (!email.contains('@') || !email.contains('.')) {
                      return l10n.validEmailRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: l10n.sendResetLink,
                  isLoading: _sending,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
