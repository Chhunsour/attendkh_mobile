import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
// import 'package:mpg_hr_mobile_app/services/auth_repository.dart';
import 'package:mpg_hr_mobile_app/components/app_logo.dart';
import 'package:mpg_hr_mobile_app/components/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/components/primary_button.dart';
import 'package:mpg_hr_mobile_app/components/secondary_button.dart';
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
      password: _passwordController.text,
    );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // GoRouter redirect handles navigation automatically
    } else if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — Full-screen Stack layout
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
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
          // ── Layer 1: Full-screen garage/workshop background image ──
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

          // ── Layer 2: Dark overlay (45 % opacity) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height,
            child: Container(color: const Color(0x73000000)),
          ),

          // ── Layer 3: Logo + branding (top-center, absolute) ──
          FadeTransition(
            opacity: _fadeAnim,
            child: const SafeArea(
              child: Align(
                alignment: Alignment(0, -0.80), // upper portion
                child: _TopBranding(),
              ),
            ),
          ),

          // ── Layer 4: Glassmorphism bottom card (slides up, overlaps image) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: formTop,

            child: SlideTransition(
              position: _slideAnim,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: BackdropFilter(
                  filter: _uiFilter(), // Custom filter import needed? Actually dart:ui is available if imported. Wait, I'll use ImageFilter from dart:ui
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withAlpha(150) 
                          : Colors.white.withAlpha(220),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withAlpha(50),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: _buildLoginForm(authState, l10n),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageFilter _uiFilter() {
    return ImageFilter.blur(sigmaX: 20, sigmaY: 20);
  }

  // ────────────────────────────────────────────
  //  LOGIN FORM (inside white bottom card)
  // ────────────────────────────────────────────
  // ignore: strict_top_level_inference
  Widget _buildLoginForm(authState, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Title ──
            Text(
              l10n.welcomeBack,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 30),

            // ── Login Identity Field ──
            CustomTextField(
              controller: _loginController,
              hintText: l10n.loginIdentityHint,
              labelText: l10n.loginIdentityLabel,
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 18),

            // ── Password Field ──
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
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.passwordRequired : null,
            ),
            const SizedBox(height: 20),

            // ── Forgot Password ──
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: GestureDetector(
            //     onTap: () => _showForgotPasswordDialog(context),
            //     child: const Text(
            //       'Forgot Password?',
            //       style: TextStyle(
            //         fontSize: 14,
            //         fontWeight: FontWeight.w500,
            //         color: _primaryBlue,
            //         fontFamily: 'Inter',
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 18),

            // ── Sign In Button ──
            PrimaryButton(
              label: l10n.signIn,
              isLoading: authState.isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 18),

            // ── OR Divider ──
            _OrDivider(l10n: l10n),
            const SizedBox(height: 18),

            // ── Create Account Button ──
            SecondaryButton(
              label: l10n.createAccount,
              onPressed: () => context.go(AppRoutes.register),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  //  FORGOT PASSWORD DIALOG
  // ────────────────────────────────────────────
//   Future<void> _showForgotPasswordDialog(BuildContext context) async {
//   final emailCtrl = TextEditingController();

//   final result = await showDialog<bool>(
//     context: context,
//     barrierDismissible: false,
//     builder: (ctx) {
//       return Dialog(
//         backgroundColor: _white,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 height: 70,
//                 width: 70,
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.lock_reset,
//                   color: Colors.blue,
//                   size: 38,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               const Text(
//                 "Forgot Password?",
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               const Text(
//                 "Enter your email address and we'll send you a password reset link.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.grey,
//                   height: 1.4,
//                 ),
//               ),

//               const SizedBox(height: 24),

//               TextField(
//                 controller: emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: InputDecoration(
//                   hintText: "Enter your email",
//                   prefixIcon: const Icon(Icons.email_outlined),
//                   filled: true,
//                   fillColor: Colors.grey.shade100,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide(
//                       color: Colors.grey.shade300,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: const BorderSide(
//                       color: Colors.blue,
//                       width: 2,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 28),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(ctx, false),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: const Text("Cancel"),
//                     ),
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(ctx, true),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: const Text(
//                         "Send Link",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );

//   if (result == true && emailCtrl.text.trim().isNotEmpty) {
//     try {
//       final repo = AuthRepository();
//       await repo.forgotPassword(emailCtrl.text.trim());

//       if (!context.mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("✅ Reset link sent. Check your email."),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       if (!context.mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ ${e.toString()}"),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
// }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TOP BRANDING — Logo + "MPG GARAGE" + tagline
// ══════════════════════════════════════════════════════════════════════════════
class _TopBranding extends StatelessWidget {
  const _TopBranding();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        const AppLogo(size: 100),
        const SizedBox(height: 16),
        // Brand name
        const Text(
          'AttendKH',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // Tagline
        Text(
          'Smart Attendance & Payroll',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
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
            color: AppColors.grey300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.or,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey400,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.grey300,
          ),
        ),
      ],
    );
  }
}