import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/services/auth_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';
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
    '1 - 15 Employees',
    '16 - 50 Employees',
    '51 - 200 Employees',
    '200+ Employees',
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
      begin: const Offset(0, 0.15),
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
          content: Text(l10n.companyPrefix + result.companyName + l10n.createdSuccessSuffix),
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — Full-screen Stack (same layout as login screen)
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    double formTop = size.height * 0.40 - viewInsets.bottom;
    if (formTop < padding.top + 20) {
      formTop = padding.top + 20;
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          // ── Layer 1: Background image ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height,
            child: Image.asset(
              'assets/images/background_image_without_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 2: Dark overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height,
            child: Container(color: const Color(0x73000000)),
          ),

          // ── Layer 3: Back button (app-bar style, top-left) ──
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 0, 0),
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: Logo + branding (top-center) ──
          FadeTransition(
            opacity: _fadeAnim,
            child: const SafeArea(
              child: Align(
                alignment: Alignment(0, -0.80),
                child: _TopBranding(),
              ),
            ),
          ),

          // ── Layer 5: White bottom card ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: formTop,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: _buildCardContent(l10n),
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
  Widget _buildCardContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            _step == 1 ? l10n.registerYourCompany : l10n.companyDetails,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 1
                ? l10n.step1Of2
                : l10n.step2Of2,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500,
            ),
          ),

          const SizedBox(height: 20),

          // ── Stepper progress bar ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _step == 2
                        ? AppColors.primary
                        : AppColors.grey200,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Error banner ──
          if (_serverError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
              ),
              child: Text(
                _serverError!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Step 1: Admin Account ──
          if (_step == 1) _buildStep1(l10n),

          // ── Step 2: Company Details ──
          if (_step == 2) _buildStep2(l10n),

          
        ],
      ),
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
          const SizedBox(height: 18),
          CustomTextField(
            controller: _userPhoneController,
            labelText: l10n.phoneNumber,
            hintText: l10n.phoneNumberHint,
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.phoneRequiredForLogin : null,
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
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
            prefixIcon: Icons.business_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.companyNameRequired : null,
          ),
          const SizedBox(height: 18),

          // ── Company Size dropdown (not a text field) ──
          SizedBox(
            height: 56,
            child: DropdownButtonFormField<String>(
              initialValue: _companySize,
              isExpanded: true,
              hint: Text(
                l10n.selectCompanySize,
                style: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 16,
                ),
              ),
              dropdownColor: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey900,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey400,
              ),
              decoration: InputDecoration(
                labelText: l10n.companySize,
                hintStyle: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 16,
                ),
                labelStyle: const TextStyle(
                  color: AppColors.grey400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.people_outline_rounded,
                  color: AppColors.grey400,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.grey200),
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
                            fontSize: 14,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _companySize = v),
              validator: (v) =>
                  v == null ? l10n.companySizeRequired : null,
            ),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _phoneController,
            labelText: l10n.phoneNumberOptional,
            hintText: l10n.phoneOptionalHint,
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
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _goToStep1,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey500,
                      side: const BorderSide(color: AppColors.grey200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.surfaceLight,
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

// ══════════════════════════════════════════════════════════════════════════════
//  TOP BRANDING — Logo + "MPG GARAGE" + tagline
// ══════════════════════════════════════════════════════════════════════════════
class _TopBranding extends StatelessWidget {
  const _TopBranding();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 100),
        const SizedBox(height: 16),
        const Text(
          'MPG GARAGE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.hrManagementSystem,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xB3FFFFFF),
          ),
        ),
      ],
    );
  }
}