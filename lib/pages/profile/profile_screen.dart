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
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.grey900,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.myProfile,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey900.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.grey200,
                  ),
                  child: data.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: data.photoUrl!,
                            width: 64,
                            height: 64,
                            memCacheWidth: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                _initials(data.name),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(data.name),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Name + email + chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildRoleChip(data.roles),
                          if (data.employmentStatus != null)
                            _buildStatusChip(data.employmentStatus!),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          l10n.editProfile,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Employment Details Card
          _buildInfoCard(
            context,
            icon: Icons.work_outline,
            iconColor: AppColors.primary,
            title: 'Employment Details',
            children: [
              if (data.employeeId != null)
                _buildInfoRow(
                  Icons.badge_outlined,
                  'Employee ID',
                  data.employeeId!,
                ),
              if (data.nationalId != null)
                _buildInfoRow(
                  Icons.perm_identity,
                  'National ID',
                  data.nationalId!,
                ),
              _buildInfoRow(
                Icons.business_outlined,
                l10n.company,
                data.companyName ?? data.companyId.toString(),
              ),
              if (data.branchName != null)
                _buildInfoRow(Icons.store_outlined, 'Branch', data.branchName!),
              if (data.department != null)
                _buildInfoRow(
                  Icons.group_work_outlined,
                  l10n.department,
                  data.department!,
                ),
              if (data.jobTitle != null)
                _buildInfoRow(
                  Icons.work_outline,
                  l10n.jobTitle,
                  data.jobTitle!,
                ),
              if (data.team != null)
                _buildInfoRow(Icons.group_outlined, 'Team', data.team!),
              if (data.manager != null)
                _buildInfoRow(Icons.person_outline, 'Manager', data.manager!),
              if (data.hireDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Join Date',
                  data.hireDate!,
                ),
              if (data.salary != null)
                _buildInfoRow(Icons.attach_money, 'Salary', '\$${data.salary}'),
            ],
          ),

          // Personal Info Card
          _buildInfoCard(
            context,
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Personal Information',
            children: [
              if (data.phone != null)
                _buildInfoRow(Icons.phone_outlined, 'Phone', data.phone!),
              if (data.gender != null)
                _buildInfoRow(
                  Icons.person_outline,
                  'Gender',
                  _capitalize(data.gender!),
                ),
              if (data.dateOfBirth != null)
                _buildInfoRow(
                  Icons.cake_outlined,
                  'Date of Birth',
                  data.dateOfBirth!,
                ),
              if (data.maritalStatus != null)
                _buildInfoRow(
                  Icons.favorite_outline,
                  'Marital Status',
                  _capitalize(data.maritalStatus!),
                ),
              if (data.address != null && data.address!.isNotEmpty)
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Address',
                  data.address!,
                ),
            ],
          ),

          // Banking & Emergency (side by side or stacked)
          if (data.bankName != null || data.bankAccount != null)
            _buildInfoCard(
              context,
              icon: Icons.account_balance_outlined,
              iconColor: Colors.green,
              title: 'Financial & Banking',
              children: [
                if (data.bankName != null)
                  _buildInfoRow(
                    Icons.account_balance_outlined,
                    'Bank Name',
                    data.bankName!,
                  ),
                if (data.bankAccount != null)
                  _buildInfoRow(
                    Icons.numbers,
                    'Account Number',
                    data.bankAccount!,
                  ),
              ],
            ),

          if (data.emergencyContact != null)
            _buildInfoCard(
              context,
              icon: Icons.emergency_outlined,
              iconColor: Colors.red,
              title: 'Emergency Contact',
              children: [
                if (data.emergencyContact!['name'] != null)
                  _buildInfoRow(
                    Icons.person_outline,
                    'Contact Name',
                    data.emergencyContact!['name'].toString(),
                  ),
                if (data.emergencyContact!['relationship'] != null)
                  _buildInfoRow(
                    Icons.people_outline,
                    'Relationship',
                    data.emergencyContact!['relationship'].toString(),
                  ),
                if (data.emergencyContact!['phone'] != null)
                  _buildInfoRow(
                    Icons.phone_outlined,
                    'Phone',
                    data.emergencyContact!['phone'].toString(),
                  ),
              ],
            ),

          // Settings Card
          _buildInfoCard(
            context,
            icon: Icons.settings_outlined,
            iconColor: AppColors.grey600,
            title: 'Access & Settings',
            children: [
              _buildSettingsRow(
                Icons.shield_outlined,
                l10n.accessRoles,
                data.roles
                    .map((r) => r.replaceAll('_', ' '))
                    .join(', ')
                    .toUpperCase(),
              ),
              if (authState.isSuperAdmin || authState.isCompanyAdmin)
                _buildTapRow(
                  Icons.admin_panel_settings_outlined,
                  l10n.returnToAdminConsole,
                  () {
                    if (authState.isSuperAdmin) {
                      context.go(AppRoutes.adminDashboard);
                    } else {
                      context.go(AppRoutes.companyAdmin);
                    }
                  },
                ),
              _buildLanguageRow(context, ref, l10n),
              _buildTapRow(
                Icons.logout,
                l10n.logOut,
                () => showLogoutConfirmation(context, ref),
                isDestructive: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoleChip(List<String> roles) {
    final roleText = roles.isNotEmpty
        ? roles.first.replaceAll('_', ' ')
        : 'Employee';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grey400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.grey700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapRow(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.danger : AppColors.grey800;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.language, size: 22, color: AppColors.grey700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.language,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ref.watch(localeProvider).languageCode,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey500),
              style: const TextStyle(fontSize: 14, color: AppColors.grey800),
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'km', child: Text(l10n.khmer)),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(newValue));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
