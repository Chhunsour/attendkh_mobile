import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.myProfile,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        
      ),
      body: profileAsync.when(
        data: (data) => _buildContent(context, ref, data, authState, l10n),
        loading: () => LoadingIndicator(message: l10n.loadingProfile),
        error: (e, _) => _buildFallback(context, ref, authState, l10n),
      ),
    );
  }

  Widget _buildFallback(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          Text(
            l10n.failedToLoadProfile,
            style: const TextStyle(color: AppColors.grey500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(profileProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProfileData data,
    AuthState authState,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture with Camera Icon Overlay
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.grey200,
                            ),
                            child: data.photoUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: data.photoUrl!,
                                      width: 80,
                                      height: 80,
                                      memCacheWidth: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Center(
                                        child: Text(
                                          _initials(data.name),
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.grey600),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initials(data.name),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ),
                          ),
                          
                        ],
                      ),
                      const SizedBox(width: 20),
                      
                      // Info & Button
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.push(AppRoutes.editProfile);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(l10n.editProfile, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Settings List
                _buildListTile(
                  icon: Icons.business_outlined,
                  title: l10n.company,
                  subtitle: data.companyName ?? data.companyId.toString(),
                  onTap: null,
                ),
                if (data.jobTitle != null)
                  _buildListTile(
                    icon: Icons.work_outline,
                    title: l10n.jobTitle,
                    subtitle: data.jobTitle,
                    onTap: null,
                  ),
                if (data.department != null)
                  _buildListTile(
                    icon: Icons.group_work_outlined,
                    title: l10n.department,
                    subtitle: data.department,
                    onTap: null,
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: AppColors.grey200),
                ),
                const SizedBox(height: 8),
                _buildListTile(
                  icon: Icons.shield_outlined,
                  title: l10n.accessRoles,
                  subtitle: data.roles.map((r) => r.replaceAll('_', ' ')).join(', ').toUpperCase(),
                  onTap: null,
                ),
                if (authState.isSuperAdmin || authState.isCompanyAdmin)
                  _buildListTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: l10n.returnToAdminConsole,
                    onTap: () {
                      if (authState.isSuperAdmin) {
                        context.go(AppRoutes.adminDashboard);
                      } else {
                        context.go(AppRoutes.companyAdmin);
                      }
                    },
                  ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: AppColors.grey200),
                ),
                const SizedBox(height: 8),
                _buildListTile(
                  icon: Icons.language,
                  title: l10n.language,
                  trailingWidget: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ref.watch(localeProvider).languageCode,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey500),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n.english),
                        ),
                        DropdownMenuItem(
                          value: 'km',
                          child: Text(l10n.khmer),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(localeProvider.notifier).setLocale(Locale(newValue));
                        }
                      },
                    ),
                  ),
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: l10n.logOut,
                  isDestructive: true,
                  onTap: () => showLogoutConfirmation(context, ref),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
    Widget? trailingWidget,
  }) {
    final color = isDestructive ? AppColors.danger : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),
              ),
            ],
            ?trailingWidget,
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.grey400),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
