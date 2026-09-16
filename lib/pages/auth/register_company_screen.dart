import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendkh/components/app_logo.dart';
import 'package:attendkh/components/custom_text_field.dart';
import 'package:attendkh/components/language_switch_button.dart';
import 'package:attendkh/components/primary_button.dart';
import 'package:attendkh/components/theme_switch_button.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/providers/auth_provider.dart';
import 'package:attendkh/utils/router/app_router.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://attendkh.com/privacy-policy';

class RegisterCompanyScreen extends ConsumerStatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  ConsumerState<RegisterCompanyScreen> createState() =>
      _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends ConsumerState<RegisterCompanyScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  final _companyNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _serverError;

  // Animation
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
      begin: const Offset(0, 0.10),
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
    _companyNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    try {
      final result = await ref.read(authProvider.notifier).registerCompany(
            companyName: _companyNameController.text.trim(),
            userName: _userNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workspace "${result.companyName}" created successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Transition to company admin dashboard
      if (mounted) {
        context.go(AppRoutes.companyAdmin);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      setState(() => _serverError = errorMsg);
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
        backgroundColor:
            isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // ── Background Gradient ──
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
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
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
                  color: const Color(0xFF6366F1)
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),

            // ── Main Content ──
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Navigation Bar ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Back button to Login
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
                                  onTap: () => context.go(AppRoutes.login),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.grey900,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Workspace Setup Badge (matching web badge)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.15 : 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                          alpha: isDark ? 0.25 : 0.20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Workspace Setup',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFF93C5FD)
                                                : AppColors.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Theme & Language toggles
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 3),
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
                                    ThemeSwitchButton(
                                        isDarkHeader: isDark, compact: true),
                                    const SizedBox(width: 4),
                                    LanguageSwitchButton(
                                        isDark: isDark, compact: true),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

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
                                          color: AppColors.primary.withValues(
                                              alpha: isDark ? 0.35 : 0.22),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const AppLogo(size: 52),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'AttendKH',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Floating Form Card ──
                          SlideTransition(
                            position: _slideAnim,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
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
                                        : AppColors.primary
                                            .withValues(alpha: 0.08),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 24, 22, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title & Subtitle (matching Web)
                                    Text(
                                      l10n.registerYourCompany,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.grey900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create your company workspace and administrator account.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        fontWeight: FontWeight.w400,
                                        color: isDark
                                            ? AppColors.grey400
                                            : AppColors.grey500,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // General Server Error Banner
                                    if (_serverError != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.badgeBg(
                                              context, AppColors.danger),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.danger
                                                .withValues(alpha: 0.35),
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
                                                style: TextStyle(
                                                  color: AppColors.badgeText(
                                                      context,
                                                      AppColors.danger),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                              ),
                                              color: AppColors.danger,
                                              onPressed: () => setState(
                                                  () => _serverError = null),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Form fields
                                    AutofillGroup(
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            // 1. Company Name
                                            CustomTextField(
                                              controller:
                                                  _companyNameController,
                                              labelText: l10n.companyName,
                                              hintText: l10n.companyNameHint,
                                              prefixIcon:
                                                  Icons.business_rounded,
                                              autofillHints: const [
                                                AutofillHints.organizationName
                                              ],
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? l10n.companyNameRequired
                                                  : null,
                                            ),
                                            const SizedBox(height: 16),

                                            // 2. Your Full Name
                                            CustomTextField(
                                              controller: _userNameController,
                                              labelText: l10n.yourFullName,
                                              hintText: l10n.johnSmith,
                                              prefixIcon:
                                                  Icons.person_outline_rounded,
                                              autofillHints: const [
                                                AutofillHints.name
                                              ],
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? l10n.fullNameRequired
                                                  : null,
                                            ),
                                            const SizedBox(height: 16),

                                            // 3. Work Email
                                            CustomTextField(
                                              controller: _emailController,
                                              labelText: l10n.workEmail,
                                              hintText: l10n.emailHint,
                                              prefixIcon:
                                                  Icons.email_outlined,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              autofillHints: const [
                                                AutofillHints.email
                                              ],
                                              validator: (v) {
                                                if (v == null ||
                                                    v.trim().isEmpty) {
                                                  return l10n.emailRequired;
                                                }
                                                if (!v.contains('@') ||
                                                    !v.contains('.')) {
                                                  return l10n.validEmailRequired;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),

                                            // 4. Phone Number
                                            CustomTextField(
                                              controller: _phoneController,
                                              labelText: l10n.phoneNumber,
                                              hintText: '012 345 678',
                                              prefixIcon:
                                                  Icons.phone_android_rounded,
                                              keyboardType:
                                                  TextInputType.phone,
                                              autofillHints: const [
                                                AutofillHints.telephoneNumber
                                              ],
                                              validator: (v) => v == null ||
                                                      v.trim().isEmpty
                                                  ? l10n.phoneRequiredForLogin
                                                  : null,
                                            ),
                                            const SizedBox(height: 16),

                                            // 5. Password
                                            CustomTextField(
                                              controller: _passwordController,
                                              labelText: l10n.password,
                                              hintText: l10n.min8Chars,
                                              prefixIcon:
                                                  Icons.lock_outline_rounded,
                                              obscureText: _obscurePassword,
                                              autofillHints: const [
                                                AutofillHints.newPassword
                                              ],
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: isDark
                                                      ? AppColors.grey400
                                                      : AppColors.grey500,
                                                  size: 21,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscurePassword =
                                                        !_obscurePassword),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return l10n.passwordRequired;
                                                }
                                                if (v.length < 8) {
                                                  return l10n.min8CharsRequired;
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 16),

                                            // 6. Confirm Password
                                            CustomTextField(
                                              controller:
                                                  _confirmPasswordController,
                                              labelText: l10n.confirmPassword,
                                              hintText:
                                                  l10n.reEnterPassword,
                                              prefixIcon:
                                                  Icons.lock_outline_rounded,
                                              obscureText:
                                                  _obscureConfirmPassword,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _submitRegistration(),
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: isDark
                                                      ? AppColors.grey400
                                                      : AppColors.grey500,
                                                  size: 21,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return l10n
                                                      .pleaseConfirmPassword;
                                                }
                                                if (v !=
                                                    _passwordController.text) {
                                                  return l10n
                                                      .passwordsDoNotMatch;
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 24),

                                            // Submit Button (Create Workspace)
                                            PrimaryButton(
                                              label: _isSubmitting
                                                  ? 'Creating Workspace…'
                                                  : l10n.createWorkspace,
                                              isLoading: _isSubmitting,
                                              onPressed: _isSubmitting
                                                  ? null
                                                  : _submitRegistration,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Already have an account? Sign in here
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.go(AppRoutes.login),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: 'Already have an account? ',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: isDark
                                                  ? AppColors.grey400
                                                  : AppColors.grey600,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Sign in here',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? const Color(0xFF60A5FA)
                                                      : AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Privacy Policy Link
                          Center(
                            child: TextButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(_privacyPolicyUrl),
                                mode: LaunchMode.inAppBrowserView,
                              ),
                              icon: Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey500,
                              ),
                              label: Text(
                                l10n.privacyPolicy,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 32),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                              ),
                            ),
                          ),
                        ],
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
}