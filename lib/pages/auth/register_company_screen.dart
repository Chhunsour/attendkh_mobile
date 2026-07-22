import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/services/auth_repository.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';

/// ── Design tokens (matching login screen) ──
const _primaryBlue = Color(0xFF4F7DF3);
const _textDark = Color(0xFF222222);
const _textSecondary = Color(0xFF777777);
const _white = Colors.white;
const _overlayColor = Color(0x73000000); // 45 % black

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
          content: Text('Company "${result.companyName}" created successfully! Please sign in.'),
          backgroundColor: const Color(0xFF22C55E),
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
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    double formTop = size.height * 0.40 - viewInsets.bottom;
    if (formTop < padding.top + 20) {
      formTop = padding.top + 20;
    }

    return Scaffold(
      backgroundColor: _white,
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
            child: Container(color: _overlayColor),
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
                      color: _white.withAlpha(51), // ~20 % white
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _white,
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
                  color: _white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: _buildCardContent(),
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
  Widget _buildCardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            _step == 1 ? 'Register Your Company' : 'Company Details',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _step == 1
                ? 'Step 1 of 2: Create your admin account.'
                : 'Step 2 of 2: Fill in your company information.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              fontFamily: 'Inter',
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
                    color: _primaryBlue,
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
                        ? _primaryBlue
                        : const Color(0xFFE5E5E5),
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
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(50)),
              ),
              child: Text(
                _serverError!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Step 1: Admin Account ──
          if (_step == 1) _buildStep1(),

          // ── Step 2: Company Details ──
          if (_step == 2) _buildStep2(),

          
        ],
      ),
    );
  }

  // ── Step 1 form ──
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        children: [
          CustomTextField(
            controller: _userNameController,
            labelText: 'Your Full Name',
            hintText: 'John Smith',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _userPhoneController,
            labelText: 'Phone Number',
            hintText: '010 123 456',
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Phone number is required for login' : null,
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _emailController,
            labelText: 'Work Email',
            hintText: 'you@company.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Min. 8 characters',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Continue',
            onPressed: _goToStep2,
          ),
        ],
      ),
    );
  }

  // ── Step 2 form ──
  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        children: [
          CustomTextField(
            controller: _companyNameController,
            labelText: 'Company Name',
            hintText: 'Acme Inc.',
            prefixIcon: Icons.business_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Company name is required' : null,
          ),
          const SizedBox(height: 18),

          // ── Company Size dropdown (not a text field) ──
          SizedBox(
            height: 56,
            child: DropdownButtonFormField<String>(
              initialValue: _companySize,
              isExpanded: true,
              hint: const Text(
                'Select company size',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
              dropdownColor: _white,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                color: _textDark,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9CA3AF),
              ),
              decoration: InputDecoration(
                labelText: 'Company Size',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
              items: _companySizes
                  .map((size) => DropdownMenuItem(
                        value: size,
                        child: Text(
                          size,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _companySize = v),
              validator: (v) =>
                  v == null ? 'Please select company size' : null,
            ),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _phoneController,
            labelText: 'Phone Number (Optional)',
            hintText: '+855 12 345 678',
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
                      foregroundColor: _textSecondary,
                      side: const BorderSide(color: Color(0xFFE5E5E5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                      backgroundColor: _white,
                    ),
                    child: const Text('Back'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: PrimaryButton(
                  label: 'Create Workspace',
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
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: 100),
        SizedBox(height: 16),
        Text(
          'MPG GARAGE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _white,
            letterSpacing: 1.2,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: 6),
        Text(
          'HR Management System',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xB3FFFFFF), // white.withAlpha(179)
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}