import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: profileAsync.when(
        data: (data) => _buildContent(context, ref, data, authState),
        loading: () => const LoadingIndicator(message: 'Loading profile...'),
        error: (e, _) => _buildFallback(context, ref, authState),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, WidgetRef ref, AuthState authState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          const Text('Failed to load profile details.', style: TextStyle(color: AppColors.grey500)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(profileProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProfileData data, AuthState authState) {
    return CustomScrollView(
      slivers: [
        // Glassmorphism Header
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Animated Gradient Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Glassmorphism Overlay
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))],
                              ),
                              child: Center(
                                child: Text(
                                  _initials(data.name),
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                data.companyName ?? 'Organization',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Grouped Settings Lists
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(icon: Icons.email_rounded, iconColor: const Color(0xFF3B82F6), title: 'Email Address', subtitle: data.email ?? '—'),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(icon: Icons.business_rounded, iconColor: const Color(0xFF8B5CF6), title: 'Company ID', subtitle: data.companyId.toString()),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(icon: Icons.shield_rounded, iconColor: const Color(0xFF10B981), title: 'Access Roles', subtitle: data.roles.map((r) => r.replaceAll('_', ' ')).join(', ').toUpperCase()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text('Account Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey500, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.edit_rounded,
                        iconColor: AppColors.primary,
                        title: 'Edit Profile',
                        onTap: () => _showEditDialog(context, ref, data),
                      ),
                      if (authState.isSuperAdmin) ...[
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Return to Admin Console',
                          onTap: () => context.go(AppRoutes.adminDashboard),
                        ),
                      ] else if (authState.isCompanyAdmin) ...[
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Return to Admin Console',
                          onTap: () => context.go(AppRoutes.companyAdmin),
                        ),
                      ],
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.danger,
                        title: 'Log Out',
                        textColor: AppColors.danger,
                        onTap: () => showLogoutConfirmation(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, ProfileData data) async {
    final nameCtrl = TextEditingController(text: data.name);
    final emailCtrl = TextEditingController(text: data.email ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true) {
      try {
        final repo = ProfileRepository();
        final name = nameCtrl.text.trim();
        final email = emailCtrl.text.trim();
        await repo.updateProfile(
          name: name.isNotEmpty ? name : null,
          email: email.isNotEmpty ? email : null,
        );
        ref.invalidate(profileProvider);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString()}'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor ?? AppColors.grey800)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                  ]
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }
}