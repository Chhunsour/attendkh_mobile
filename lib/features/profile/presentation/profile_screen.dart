import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/profile/data/profile_repository.dart';
import 'package:mpg_hr_mobile_app/features/profile/presentation/profile_provider.dart';
import 'package:mpg_hr_mobile_app/shared/widgets/loading_indicator.dart';

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
            width: 96, height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])),
            child: Center(child: Text(_initials(authState.userName ?? 'User'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(height: 12),
          Text(authState.userName ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(authState.companyName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
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
            width: 96, height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])),
            child: Center(child: Text(_initials(data.name), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(height: 12),
          Text(data.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey800)),
          const SizedBox(height: 4),
          Text(data.companyName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          _ProfileInfoCard(title: 'Email', value: data.email ?? '—', icon: Icons.email_outlined),
          _ProfileInfoCard(title: 'Company ID', value: data.companyId.toString(), icon: Icons.business_outlined),
          _ProfileInfoCard(title: 'Roles', value: data.roles.map((r) => r.replaceAll('_', ' ').replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase())).join(', '), icon: Icons.shield_outlined),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey500),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.grey800)),
          ]),
        ],
      ),
    );
  }
}