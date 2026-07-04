import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/features/auth/data/auth_repository.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/app_logo.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/custom_text_field.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/primary_button.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/secondary_button.dart';

/// ── Design tokens (matches prompt spec) ──
const _primaryBlue = Color(0xFF4F7DF3);
const _textDark = Color(0xFF222222);
const _white = Colors.white;

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

    return Scaffold(
      backgroundColor: _white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-screen garage/workshop background image ──
          Image.asset(
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

          // ── Layer 2: Dark overlay (45 % opacity) ──
          Container(color: const Color(0x73000000)),

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

          // ── Layer 4: White bottom card (slides up, overlaps image) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.of(context).size.height * 0.40,
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
                child: _buildLoginForm(authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  //  LOGIN FORM (inside white bottom card)
  // ────────────────────────────────────────────
  // ignore: strict_top_level_inference
  Widget _buildLoginForm(authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Title ──
            const Text(
              'សូមស្វាគមន៍', // "Welcome" in Khmer
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 30),

            // ── Login Identity Field ──
            CustomTextField(
              controller: _loginController,
              hintText: 'user@email.com, 010123456, or EMP01',
              labelText: 'Email, Phone, or Employee ID',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.text,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'This field is required' : null,
            ),
            const SizedBox(height: 18),

            // ── Password Field ──
            CustomTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              labelText: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
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
              validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 10),

            // ── Forgot Password ──
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showForgotPasswordDialog(context),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryBlue,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Sign In Button ──
            PrimaryButton(
              label: 'Sign In',
              isLoading: authState.isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 18),

            // ── OR Divider ──
            const _OrDivider(),
            const SizedBox(height: 18),

            // ── Create Account Button ──
            SecondaryButton(
              label: 'Create Account',
              onPressed: () => context.go(AppRoutes.register),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address and we\'ll send you a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );

    if (result == true && emailCtrl.text.trim().isNotEmpty) {
      try {
        final repo = AuthRepository();
        await repo.forgotPassword(emailCtrl.text.trim());
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reset link sent. Check your email.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
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
          'MPG GARAGE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _white,
            letterSpacing: 1.2,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        // Tagline
        Text(
          'HR Management System',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: _white.withAlpha(179),
            fontFamily: 'Inter',
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
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFE5E5E5),
            thickness: 0.5,
            endIndent: 12,
          ),
        ),
        Text(
          'OR',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
            fontFamily: 'Inter',
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFE5E5E5),
            thickness: 0.5,
            indent: 12,
          ),
        ),
      ],
    );
  }
}