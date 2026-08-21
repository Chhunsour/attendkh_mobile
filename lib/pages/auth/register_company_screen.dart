import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/services/auth_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';
import 'package:mpg_hr_mobile_app/components/language_switch_button.dart';
import 'package:mpg_hr_mobile_app/components/theme_switch_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

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
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFF071228),
      body: Stack(
        children: [
          // ── Layer 1: Tech Gradient Background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
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
                          const SizedBox(height: 48),

                          // Top Header Branding
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withAlpha(120),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const AppLogo(size: 72),
                                  ),
                                  const SizedBox(height: 10),
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
                                      color: Colors.white.withAlpha(190),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

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
                                  child: _buildCardContent(l10n, isDark),
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

          // ── Layer 3: Top Navigation (Back Button + Language Switcher) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_step == 2) {
                        _goToStep1();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
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
    );
  }

  // ────────────────────────────────────────────
  //  CARD CONTENT — stepper + form
  // ────────────────────────────────────────────
  Widget _buildCardContent(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Subtitle ──
          Text(
            _step == 1 ? l10n.registerYourCompany : l10n.companyDetails,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 1 ? l10n.step1Of2 : l10n.step2Of2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),

          const SizedBox(height: 18),

          // ── Visual 2-Step Progress Indicator ──
          Row(
            children: [
              _buildStepIndicator(
                stepNumber: 1,
                label: l10n.step1Of2.split(':').first,
                isActive: _step >= 1,
                isCurrent: _step == 1,
              ),
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _step == 2
                        ? AppColors.primary
                        : AppColors.grey200,
                  ),
                ),
              ),
              _buildStepIndicator(
                stepNumber: 2,
                label: l10n.step2Of2.split(':').first,
                isActive: _step == 2,
                isCurrent: _step == 2,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Error banner ──
          if (_serverError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withAlpha(120),
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
                    fontSize: 13,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Privacy Policy Link (Apple Guideline 5.1.1)
          Center(
            child: TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://attendkh.com/privacy-policy'),
                mode: LaunchMode.inAppBrowserView,
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCurrent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.grey200,
            border: isCurrent
                ? Border.all(color: AppColors.primaryLight, width: 3)
                : null,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.grey500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1 form ──
  Widget _buildStep1(AppLocalizations l10n) {
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
                color: AppColors.grey400,
                size: 22,
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
                color: AppColors.grey400,
                size: 22,
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
          const SizedBox(height: 24),
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
              style: const TextStyle(
                color: AppColors.grey400,
                fontSize: 14,
              ),
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.grey900,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400,
            ),
            decoration: InputDecoration(
              labelText: l10n.companySize,
              labelStyle: const TextStyle(
                color: AppColors.grey500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.grey400,
                size: 22,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.grey800
                  : AppColors.grey50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
            ),
            items: _companySizes
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text(
                        size,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
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
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
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