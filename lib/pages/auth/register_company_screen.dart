import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendkh/services/auth_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/components/app_logo.dart';
import 'package:attendkh/components/custom_text_field.dart';
import 'package:attendkh/components/primary_button.dart';
import 'package:attendkh/components/language_switch_button.dart';
import 'package:attendkh/components/theme_switch_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendkh/l10n/app_localizations.dart';

class RegisterCompanyScreen extends ConsumerStatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  ConsumerState<RegisterCompanyScreen> createState() =>
      _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState
    extends ConsumerState<RegisterCompanyScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1;

  // ── Step 1: Admin Account ──
  final _userNameController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ── Step 2: Company Details ──
  final _companyNameController = TextEditingController();
  String? _companySize;
  final _phoneController = TextEditingController();

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _serverError;

  // ── Animation ──
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _companySizes = [
    '1 - 15 Employees (SME / សហគ្រាសធុនតូច)',
    '16 - 50 Employees (Medium / មធ្យម)',
    '51 - 200 Employees (Large / ធំ)',
    '200+ Employees (Enterprise / សាជីវកម្ម)',
  ];

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
    _userNameController.dispose();
    _userPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Wizard navigation ──
  void _goToStep2() {
    if (!_formKeyStep1.currentState!.validate()) return;
    setState(() {
      _step = 2;
      _serverError = null;
    });
  }

  void _goToStep1() {
    setState(() {
      _step = 1;
      _serverError = null;
    });
  }

  // ── Submit ──
  Future<void> _submitRegistration() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.registerCompany(
        userName: _userNameController.text.trim(),
        userPhone: _userPhoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        companyName: _companyNameController.text.trim(),
        companySize: _companySize,
        companyPhone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.companyPrefix +
                result.companyName +
                l10n.createdSuccessSuffix,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

            // ── Ambient Glows ──
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

            // ── Layer 2: Main Content ──
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
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
                            // ── Top Navigation Bar ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Material(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.85),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : AppColors.border(context),
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      if (_step == 2) {
                                        _goToStep1();
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        size: 20,
                                        color: isDark ? Colors.white : AppColors.grey900,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Top Step Indicator Badge — Flexible so it shrinks on narrow screens
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.08 : 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: isDark ? 0.12 : 0.15),
                                      ),
                                    ),
                                    child: Text(
                                      _step == 1 ? 'Step 1: Admin Profile' : 'Step 2: Company Info',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : AppColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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

                            const SizedBox(height: 20),

                            // ── Branding Header ──
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const AppLogo(size: 56),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'AttendKH',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Floating Form Card ──
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
                                child: _buildCardContent(l10n, isDark),
                              ),
                            ),

                            const Spacer(),

                            const SizedBox(height: 16),

                            // Privacy Policy Link
                            Center(
                              child: TextButton.icon(
                                onPressed: () => launchUrl(
                                  Uri.parse('https://attendkh.com/privacy-policy'),
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

  // ────────────────────────────────────────────
  //  CARD CONTENT — stepper + form
  // ────────────────────────────────────────────
  Widget _buildCardContent(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Subtitle ──
          Text(
            _step == 1 ? l10n.registerYourCompany : l10n.companyDetails,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.grey900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 1 ? l10n.step1Of2 : l10n.step2Of2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.grey400 : AppColors.grey500,
            ),
          ),

          const SizedBox(height: 18),

          // ── Modern 2-Step Progress Indicator ──
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: _step == 2
                        ? AppColors.primary
                        : (isDark ? AppColors.grey700 : AppColors.grey200),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Error banner ──
          if (_serverError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _serverError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Step 1: Admin Account ──
          if (_step == 1) _buildStep1(l10n),

          // ── Step 2: Company Details ──
          if (_step == 2) _buildStep2(l10n),

          const SizedBox(height: 16),

          // ── Already have account? Sign in ──
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1 form ──
  Widget _buildStep1(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKeyStep1,
      child: Column(
        children: [
          CustomTextField(
            controller: _userNameController,
            labelText: l10n.yourFullName,
            hintText: l10n.johnSmith,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.fullNameRequired : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _userPhoneController,
            labelText: l10n.phoneNumber,
            hintText: '012 345 678 / +855 12 345 678',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.phoneRequiredForLogin : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            labelText: l10n.workEmail,
            hintText: l10n.emailHint,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailRequired;
              if (!v.contains('@') || !v.contains('.')) {
                return l10n.validEmailRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            labelText: l10n.password,
            hintText: l10n.min8Chars,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
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
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.passwordRequired;
              if (v.length < 8) return l10n.min8CharsRequired;
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: l10n.confirmPassword,
            hintText: l10n.reEnterPassword,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
                size: 21,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.pleaseConfirmPassword;
              if (v != _passwordController.text) {
                return l10n.passwordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: l10n.continueText,
            onPressed: _goToStep2,
          ),
        ],
      ),
    );
  }

  // ── Step 2 form ──
  Widget _buildStep2(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKeyStep2,
      child: Column(
        children: [
          CustomTextField(
            controller: _companyNameController,
            labelText: l10n.companyName,
            hintText: l10n.companyNameHint,
            prefixIcon: Icons.business_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.companyNameRequired : null,
          ),
          const SizedBox(height: 16),

          // ── Company Size dropdown ──
          DropdownButtonFormField<String>(
            initialValue: _companySize,
            isExpanded: true,
            hint: Text(
              l10n.selectCompanySize,
              style: TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                fontSize: 14,
              ),
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400,
            ),
            decoration: InputDecoration(
              labelText: l10n.companySize,
              labelStyle: TextStyle(
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.people_outline_rounded,
                  color: AppColors.grey400,
                  size: 21,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.grey50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
            ),
            items: _companySizes
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text(
                        size,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _companySize = v),
            validator: (v) =>
                v == null ? l10n.companySizeRequired : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            labelText: l10n.phoneNumberOptional,
            hintText: '+855 23 888 999 / 012 345 678',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // ── Back + Submit buttons ──
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _goToStep1,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.grey700,
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.border(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(l10n.back),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: PrimaryButton(
                  label: l10n.createWorkspace,
                  isLoading: _isSubmitting,
                  onPressed: _submitRegistration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}