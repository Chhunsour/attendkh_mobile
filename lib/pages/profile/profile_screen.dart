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
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.grey900,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          l10n.myProfile,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: l10n.editProfile,
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profileProvider),
        color: AppColors.primary,
        child: profileAsync.when(
          data: (data) => _buildContent(context, ref, data, authState, l10n),
          loading: () => LoadingIndicator(message: l10n.loadingProfile),
          error: (e, _) => _buildFallback(context, ref, authState, l10n),
        ),
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
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        children: [
          // ── Header Profile Hero Card ──
          _buildHeroProfileHeader(context, data, l10n),

          // ── Key Metrics Overview Strip ──
          _buildQuickOverviewStrip(data),

          const SizedBox(height: 8),

          // ── Employment Details Card ──
          _buildSectionCard(
            title: 'Employment Details',
            icon: Icons.badge_outlined,
            iconColor: AppColors.primary,
            children: [
              if (data.employeeId != null && data.employeeId!.isNotEmpty)
                _buildInfoTile('Employee ID', data.employeeId!, Icons.fingerprint_rounded),
              _buildInfoTile(l10n.company, data.companyName ?? data.companyId.toString(), Icons.business_rounded),
              if (data.branchName != null)
                _buildInfoTile('Branch', data.branchName!, Icons.storefront_rounded),
              if (data.department != null)
                _buildInfoTile(l10n.department, data.department!, Icons.corporate_fare_rounded),
              if (data.jobTitle != null)
                _buildInfoTile(l10n.jobTitle, data.jobTitle!, Icons.work_outline_rounded),
              if (data.team != null)
                _buildInfoTile('Team', data.team!, Icons.groups_rounded),
              if (data.manager != null)
                _buildInfoTile('Reporting Manager', data.manager!, Icons.person_pin_rounded),
              if (data.hireDate != null)
                _buildInfoTile('Join Date', data.hireDate!, Icons.calendar_today_rounded),
              if (data.employmentType != null)
                _buildInfoTile('Employment Type', _capitalize(data.employmentType!), Icons.assignment_ind_outlined),
            ],
          ),

          // ── Personal Information Card ──
          _buildSectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF3B82F6),
            children: [
              if (data.phone != null && data.phone!.isNotEmpty)
                _buildInfoTile('Phone Number', data.phone!, Icons.phone_outlined),
              if (data.email != null && data.email!.isNotEmpty)
                _buildInfoTile('Email Address', data.email!, Icons.mail_outline_rounded),
              if (data.gender != null)
                _buildInfoTile('Gender', _capitalize(data.gender!), Icons.wc_rounded),
              if (data.dateOfBirth != null)
                _buildInfoTile('Date of Birth', data.dateOfBirth!, Icons.cake_outlined),
              if (data.maritalStatus != null)
                _buildInfoTile('Marital Status', _capitalize(data.maritalStatus!), Icons.favorite_border_rounded),
              if (data.nationalId != null && data.nationalId!.isNotEmpty)
                _buildInfoTile('National ID', data.nationalId!, Icons.credit_card_rounded),
              if (data.address != null && data.address!.isNotEmpty)
                _buildInfoTile('Address', data.address!, Icons.location_on_outlined),
            ],
          ),

          // ── Banking & Payroll Card ──
          if (data.bankName != null || data.bankAccount != null)
            _buildSectionCard(
              title: 'Banking & Financials',
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFF10B981),
              children: [
                if (data.bankName != null)
                  _buildInfoTile('Bank Name', data.bankName!, Icons.account_balance_rounded),
                if (data.bankAccount != null)
                  _buildInfoTile('Account Number', data.bankAccount!, Icons.numbers_rounded),
              ],
            ),

          // ── Emergency Contact Card ──
          if (data.emergencyContact != null)
            _buildSectionCard(
              title: 'Emergency Contact',
              icon: Icons.emergency_outlined,
              iconColor: const Color(0xFFEF4444),
              children: [
                if (data.emergencyContact!['name'] != null)
                  _buildInfoTile('Contact Name', data.emergencyContact!['name'].toString(), Icons.person_outline_rounded),
                if (data.emergencyContact!['relationship'] != null)
                  _buildInfoTile('Relationship', data.emergencyContact!['relationship'].toString(), Icons.people_outline_rounded),
                if (data.emergencyContact!['phone'] != null)
                  _buildInfoTile('Phone Number', data.emergencyContact!['phone'].toString(), Icons.phone_in_talk_rounded),
              ],
            ),

          // ── Account & Preferences Card ──
          _buildSectionCard(
            title: 'Preferences & Security',
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF6366F1),
            children: [
              if (authState.isSuperAdmin || authState.isCompanyAdmin) ...[
                _buildActionTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: l10n.returnToAdminConsole,
                  subtitle: 'Switch to HR Admin dashboard',
                  onTap: () {
                    if (authState.isSuperAdmin) {
                      context.go(AppRoutes.adminDashboard);
                    } else {
                      context.go(AppRoutes.companyAdmin);
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.grey100),
              ],
              _buildLanguageTile(context, ref, l10n),
              _buildActionTile(
                icon: Icons.edit_note_rounded,
                title: 'Edit Profile Information',
                subtitle: 'Update your personal and contact details',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              const Divider(height: 1, color: AppColors.grey100),
              _buildActionTile(
                icon: Icons.logout_rounded,
                title: l10n.logOut,
                subtitle: 'Sign out from this device',
                iconColor: AppColors.danger,
                titleColor: AppColors.danger,
                onTap: () => showLogoutConfirmation(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroProfileHeader(BuildContext context, ProfileData data, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Edit Button Overlay
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: data.photoUrl!,
                          width: 84,
                          height: 84,
                          memCacheWidth: 250,
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
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(data.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.editProfile),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Job Title & Department
          Text(
            [data.jobTitle, data.department].where((s) => s != null && s.isNotEmpty).join(' • '),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Roles & Status Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoleTag(data.roles),
              const SizedBox(width: 8),
              _buildStatusTag(data.employmentStatus ?? 'active'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverviewStrip(ProfileData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _overviewBox(
              'Branch',
              data.branchName ?? 'Headquarters',
              Icons.storefront_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _overviewBox(
              'Employee ID',
              data.employeeId ?? '#${data.id}',
              Icons.badge_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _overviewBox(
              'Status',
              _capitalize(data.employmentStatus ?? 'Active'),
              Icons.verified_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTag(List<String> roles) {
    final roleText = roles.isNotEmpty ? roles.first.replaceAll('_', ' ') : 'Employee';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final validChildren = children.where((w) => w is! SizedBox).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: validChildren),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.grey400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.grey700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final currentLang = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, size: 20, color: AppColors.grey700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  currentLang == 'km' ? l10n.khmer : l10n.english,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentLang,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey500),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'km', child: Text(l10n.khmer)),
              ],
              onChanged: (String? val) {
                if (val != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(val));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
