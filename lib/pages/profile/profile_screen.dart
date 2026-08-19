import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';
import 'package:mpg_hr_mobile_app/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.grey900,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          l10n.myProfile,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
              ),
              tooltip: l10n.editProfile,
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profileProvider),
        color: AppColors.primary,
        child: profileAsync.when(
          data: (data) => _buildContent(context, ref, data, authState, l10n, isDark),
          loading: () => LoadingIndicator(message: l10n.loadingProfile),
          error: (e, _) => _buildFallback(context, ref, authState, l10n, isDark),
        ),
      ),
    );
  }

  Widget _buildFallback(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: isDark ? AppColors.grey600 : AppColors.grey400),
            const SizedBox(height: 12),
            Text(
              l10n.failedToLoadProfile,
              style: TextStyle(color: isDark ? AppColors.grey400 : AppColors.grey500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(profileProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProfileData data,
    AuthState authState,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // ── Clean Executive Hero Header ──
          _buildHeroHeader(context, data, l10n, isDark),

          const SizedBox(height: 14),

          // ── High-Value Key Metric Pills (Non-Redundant) ──
          _buildKeyStatsStrip(context, data, isDark),

          const SizedBox(height: 14),

          // ── Employment & Work Details Card ──
          _buildSectionCard(
            context: context,
            title: 'Employment Details',
            icon: Icons.business_center_rounded,
            iconColor: AppColors.primary,
            isDark: isDark,
            children: [
              _buildInfoRow(
                context: context,
                label: 'Company',
                value: data.companyName ?? (data.companyId > 0 ? 'Company #${data.companyId}' : '—'),
                icon: Icons.domain_rounded,
                isDark: isDark,
              ),
              if (data.branchName != null && data.branchName!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Branch Location',
                  value: data.branchName!,
                  icon: Icons.storefront_rounded,
                  isDark: isDark,
                ),
              if (data.department != null && data.department!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Department',
                  value: data.department!,
                  icon: Icons.account_tree_rounded,
                  isDark: isDark,
                ),
              if (data.jobTitle != null && data.jobTitle!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Job Title / Role',
                  value: data.jobTitle!,
                  icon: Icons.work_outline_rounded,
                  isDark: isDark,
                ),
              if (data.team != null && data.team!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Team',
                  value: data.team!,
                  icon: Icons.groups_rounded,
                  isDark: isDark,
                ),
              if (data.manager != null && data.manager!.trim().isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Reporting Manager',
                  value: data.manager!.trim(),
                  icon: Icons.person_pin_rounded,
                  isDark: isDark,
                ),
              if (data.hireDate != null && data.hireDate!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Joining Date',
                  value: formatDate(data.hireDate),
                  icon: Icons.calendar_today_rounded,
                  isDark: isDark,
                ),
              if (data.probationEndDate != null && data.probationEndDate!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Probation End',
                  value: formatDate(data.probationEndDate),
                  icon: Icons.event_available_rounded,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Contact & Personal Information Card ──
          _buildSectionCard(
            context: context,
            title: 'Personal & Contact',
            icon: Icons.contact_page_rounded,
            iconColor: const Color(0xFF0284C7),
            isDark: isDark,
            children: [
              if (data.phone != null && data.phone!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Phone Number',
                  value: data.phone!,
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                  isCopyable: true,
                ),
              if (data.email != null && data.email!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Email Address',
                  value: data.email!,
                  icon: Icons.mail_outline_rounded,
                  isDark: isDark,
                  isCopyable: true,
                ),
              if (data.gender != null && data.gender!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Gender',
                  value: _capitalize(data.gender!),
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
              if (data.dateOfBirth != null && data.dateOfBirth!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Date of Birth',
                  value: formatDate(data.dateOfBirth),
                  icon: Icons.cake_outlined,
                  isDark: isDark,
                ),
              if (data.nationalId != null && data.nationalId!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'National ID / Passport',
                  value: data.nationalId!,
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  isCopyable: true,
                ),
              if (data.address != null && data.address!.isNotEmpty)
                _buildInfoRow(
                  context: context,
                  label: 'Residential Address',
                  value: data.address!,
                  icon: Icons.location_on_outlined,
                  isDark: isDark,
                ),
            ],
          ),

          // ── Banking & Payroll Card (Conditional) ──
          if ((data.bankName != null && data.bankName!.isNotEmpty) ||
              (data.bankAccount != null && data.bankAccount!.isNotEmpty)) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              context: context,
              title: 'Payroll & Banking',
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xFF10B981),
              isDark: isDark,
              children: [
                if (data.bankName != null && data.bankName!.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: 'Bank Name',
                    value: data.bankName!,
                    icon: Icons.account_balance_outlined,
                    isDark: isDark,
                  ),
                if (data.bankAccount != null && data.bankAccount!.isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: 'Account Number',
                    value: data.bankAccount!,
                    icon: Icons.credit_card_rounded,
                    isDark: isDark,
                    isCopyable: true,
                  ),
              ],
            ),
          ],

          // ── Emergency Contact Card (Conditional) ──
          if (_hasEmergencyContact(data.emergencyContact)) ...[
            const SizedBox(height: 14),
            _buildSectionCard(
              context: context,
              title: 'Emergency Contact',
              icon: Icons.health_and_safety_rounded,
              iconColor: const Color(0xFFEF4444),
              isDark: isDark,
              children: [
                if (data.emergencyContact!['name'] != null &&
                    data.emergencyContact!['name'].toString().isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: 'Contact Name',
                    value: data.emergencyContact!['name'].toString(),
                    icon: Icons.person_rounded,
                    isDark: isDark,
                  ),
                if (data.emergencyContact!['relationship'] != null &&
                    data.emergencyContact!['relationship'].toString().isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: 'Relationship',
                    value: data.emergencyContact!['relationship'].toString(),
                    icon: Icons.family_restroom_rounded,
                    isDark: isDark,
                  ),
                if (data.emergencyContact!['phone'] != null &&
                    data.emergencyContact!['phone'].toString().isNotEmpty)
                  _buildInfoRow(
                    context: context,
                    label: 'Emergency Phone',
                    value: data.emergencyContact!['phone'].toString(),
                    icon: Icons.phone_in_talk_rounded,
                    isDark: isDark,
                    isCopyable: true,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // ── Preferences & Account Settings Card ──
          _buildSectionCard(
            context: context,
            title: 'Preferences & Account',
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF8B5CF6),
            isDark: isDark,
            children: [
              if (authState.isSuperAdmin || authState.isCompanyAdmin) ...[
                _buildActionRow(
                  icon: Icons.admin_panel_settings_rounded,
                  title: l10n.returnToAdminConsole,
                  subtitle: 'Switch to HR Admin dashboard',
                  iconColor: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: () {
                    if (authState.isSuperAdmin) {
                      context.go(AppRoutes.adminDashboard);
                    } else {
                      context.go(AppRoutes.companyAdmin);
                    }
                  },
                ),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
              ],
              _buildThemeRow(context, ref, isDark),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
              _buildLanguageRow(context, ref, l10n, isDark),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
              _buildActionRow(
                icon: Icons.edit_note_rounded,
                title: l10n.editProfile,
                subtitle: 'Update your contact and bank details',
                iconColor: AppColors.primary,
                isDark: isDark,
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
              _buildActionRow(
                icon: Icons.logout_rounded,
                title: l10n.logOut,
                subtitle: 'Sign out from this device',
                iconColor: AppColors.danger,
                titleColor: AppColors.danger,
                isDark: isDark,
                onTap: () => showLogoutConfirmation(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // ── Hero Profile Header ──
  Widget _buildHeroHeader(
    BuildContext context,
    ProfileData data,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final displayName = data.fullName != null && data.fullName!.isNotEmpty
        ? data.fullName!
        : data.name;
    final departmentRole = [
      data.jobTitle,
      data.department,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');

    final bool isActive = (data.employmentStatus ?? 'active').toLowerCase() == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Edit Camera Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052FF), Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: data.photoUrl!,
                            width: 82,
                            height: 82,
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
                                _initials(displayName),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _initials(displayName),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Camera edit icon on avatar
              Positioned(
                bottom: 0,
                right: -2,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.editProfile),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Full Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.grey900,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),

          // Khmer Name (if available)
          if (data.khmerName != null && data.khmerName!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              data.khmerName!.trim(),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (departmentRole.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              departmentRole,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 12),

          // Badges: Role & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoleBadge(data.roles, isDark),
              const SizedBox(width: 8),
              _buildStatusBadge(isActive, data.employmentStatus ?? 'Active', isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ── High-Value Key Stats Strip (Non-Redundant) ──
  Widget _buildKeyStatsStrip(BuildContext context, ProfileData data, bool isDark) {
    final empId = data.employeeId != null && data.employeeId!.isNotEmpty
        ? data.employeeId!
        : '#${data.id}';
    final empType = _formatEmploymentType(data.employmentType);
    final joinDate = formatDate(data.hireDate);

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context: context,
            icon: Icons.badge_rounded,
            label: 'Employee ID',
            value: empId,
            color: const Color(0xFF0052FF),
            isDark: isDark,
            onTap: () => _copyToClipboard(context, empId, 'Employee ID'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context: context,
            icon: Icons.work_history_rounded,
            label: 'Employment',
            value: empType,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context: context,
            icon: Icons.event_note_rounded,
            label: 'Joined',
            value: joinDate != '—' ? joinDate : 'Recent',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Card Container ──
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    required bool isDark,
  }) {
    final validChildren = children.where((w) => w is! SizedBox).toList();
    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.grey100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: validChildren),
          ),
        ],
      ),
    );
  }

  // ── Info Row Item with Clean Icons and 1-Tap Copy ──
  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    bool isCopyable = false,
  }) {
    if (value.trim().isEmpty || value == '—') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.grey500 : AppColors.grey400),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.grey400 : AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Row Item ──
  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? (isDark ? AppColors.grey300 : AppColors.grey700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? (isDark ? Colors.white : AppColors.grey900),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.grey400 : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.grey500 : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Appearance Theme Switcher ──
  Widget _buildThemeRow(BuildContext context, WidgetRef ref, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);

    final String modeLabel = switch (themeMode) {
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
      ThemeMode.system => 'System Default',
    };

    final IconData modeIcon = switch (themeMode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              modeIcon,
              size: 18,
              color: themeMode == ThemeMode.light
                  ? const Color(0xFFF59E0B)
                  : (themeMode == ThemeMode.dark
                      ? const Color(0xFF818CF8)
                      : AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme & Appearance',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: themeMode,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('Auto')),
              ],
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Selector ──
  Widget _buildLanguageRow(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final currentLang = ref.watch(localeProvider).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 18,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                Text(
                  currentLang == 'km' ? l10n.khmer : l10n.english,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentLang,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
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

  // ── Badges ──
  Widget _buildRoleBadge(List<String> roles, bool isDark) {
    final roleText = roles.isNotEmpty ? roles.first.replaceAll('_', ' ') : 'Employee';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x283B82F6) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF93C5FD) : AppColors.primaryDark,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, String status, bool isDark) {
    final Color badgeColor = isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF6EE7B7) : AppColors.secondaryDark,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  bool _hasEmergencyContact(Map<String, dynamic>? contact) {
    if (contact == null) return false;
    final name = contact['name']?.toString() ?? '';
    final phone = contact['phone']?.toString() ?? '';
    return name.trim().isNotEmpty || phone.trim().isNotEmpty;
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied $label to clipboard', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.grey900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatEmploymentType(String? type) {
    if (type == null || type.isEmpty) return 'Full Time';
    final clean = type.replaceAll('_', ' ').toLowerCase();
    if (clean == 'full time') return 'Full Time';
    if (clean == 'part time') return 'Part Time';
    if (clean == 'contract') return 'Contract';
    if (clean == 'intern' || clean == 'internship') return 'Internship';
    if (clean == 'probation') return 'Probation';
    return clean.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
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
