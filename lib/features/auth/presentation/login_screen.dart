import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      // Route to admin or company based on role
      if (authState.isSuperAdmin) {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'MPG',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MPG GARAGE',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to your workspace',
                    style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(179)),
                  ),
                  const SizedBox(height: 40),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _loginController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email or Employee ID',
                              hintText: 'you@company.com',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.grey400),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grey400),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.grey400,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}