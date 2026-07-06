import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _formKeyProfile = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  late final ProfileRepository _profileRepo;

  @override
  void initState() {
    super.initState();
    _profileRepo = ProfileRepository();
    
    // Using current auth state for initial values
    final auth = ref.read(authProvider);
    _nameController = TextEditingController(text: auth.userName ?? '');
    _emailController = TextEditingController(text: auth.userEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKeyProfile.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      await _profileRepo.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // We should ideally sync this back to AuthNotifier, but the easiest
      // approach here is to let checkAuthStatus() pull the latest user data,
      // or we can manually update the state if we wanted. 
      // For now, checkAuthStatus will refresh the whole user.
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    try {
      await _profileRepo.updatePassword(
        currentPassword: _currentPasswordController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );

      if (mounted) {
        _currentPasswordController.clear();
        _passwordController.clear();
        _passwordConfirmController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKeyProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800)),
                    const SizedBox(height: 6),
                    const Text('Update your account\'s profile information and email address.', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                    const SizedBox(height: 24),

                    // Name
                    _buildLabel('Name'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildLabel('Email'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingProfile ? null : _saveProfile,
                        icon: _isSavingProfile
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(_isSavingProfile ? 'Saving...' : 'Save Profile', style: const TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Update Password Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKeyPassword,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey800)),
                    const SizedBox(height: 6),
                    const Text('Ensure your account is using a long, random password to stay secure.', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                    const SizedBox(height: 24),

                    _buildLabel('Current Password'),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('New Password'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (v.length < 8) return 'Min 8 chars';
                        return null;
                      },
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Confirm Password'),
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: true,
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingPassword ? null : _savePassword,
                        icon: _isSavingPassword
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.lock_rounded, size: 20),
                        label: Text(_isSavingPassword ? 'Saving...' : 'Update Password', style: const TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey700)),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.grey200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.grey200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger)),
    );
  }
}
