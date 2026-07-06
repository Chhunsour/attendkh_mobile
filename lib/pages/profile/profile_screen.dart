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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (data) => _buildContent(context, ref, data),
        loading: () => const LoadingIndicator(message: 'Loading profile...'),
        error: (e, _) => _buildFallback(context, ref, authState),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, WidgetRef ref, AuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 104, height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withAlpha(40), width: 4),
            ),
            child: Center(
              child: Text(
                _initials(authState.userName ?? 'User'),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(authState.userName ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryLight.withAlpha(150), borderRadius: BorderRadius.circular(20)),
            child: Text(authState.companyName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => ref.invalidate(profileProvider), icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ProfileData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 104, height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withAlpha(40), width: 4),
            ),
            child: Center(
              child: Text(
                _initials(data.name),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(data.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryLight.withAlpha(150), borderRadius: BorderRadius.circular(20)),
            child: Text(data.companyName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          _ProfileInfoCard(title: 'Email', value: data.email ?? '—', icon: Icons.email_outlined),
          _ProfileInfoCard(title: 'Company ID', value: data.companyId.toString(), icon: Icons.business_outlined),
          _ProfileInfoCard(title: 'Roles', value: data.roles.map((r) => r.replaceAll('_', ' ').replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase())).join(', '), icon: Icons.shield_outlined),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditDialog(context, ref, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          if (ref.watch(authProvider).isSuperAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.adminDashboard),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                label: const Text('Return to Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showLogoutConfirmation(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.dangerLight, width: 2),
                backgroundColor: AppColors.dangerLight.withAlpha(80),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
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

class _ProfileInfoCard extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const _ProfileInfoCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grey500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}