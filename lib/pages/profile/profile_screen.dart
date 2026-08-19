import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/utils/date_format_utils.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider),
          color: AppColors.primary,
          child: profileAsync.when(
            data: (data) => _buildContent(context, ref, data, l10n, isDark),
            loading: () => LoadingIndicator(message: l10n.loadingProfile),
            error: (e, _) => _buildFallback(context, ref, l10n, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
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
    AppLocalizations l10n,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // ── Royal Blue Gradient Hero Header (Matches Home / Leave Screen) ──
          _buildRoyalHeroHeader(context, data, l10n, isDark),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ── High-Value Key Metric Cards ──
                _buildKeyStatsStrip(context, data, isDark),

                const SizedBox(height: 16),

                // ── Section 1: Employment & Work Details ──
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
                      value: data.companyName ??
                          (data.companyId > 0 ? 'Company #${data.companyId}' : '—'),
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
                    if (data.probationEndDate != null &&
                        data.probationEndDate!.isNotEmpty)
                      _buildInfoRow(
                        context: context,
                        label: 'Probation End',
                        value: formatDate(data.probationEndDate),
                        icon: Icons.event_available_rounded,
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Section 2: Personal & Contact Information ──
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

                // ── Section 3: Banking & Payroll (Conditional) ──
                if ((data.bankName != null && data.bankName!.isNotEmpty) ||
                    (data.bankAccount != null && data.bankAccount!.isNotEmpty)) ...[
                  const SizedBox(height: 16),
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

                // ── Section 4: Emergency Contact (Conditional) ──
                if (_hasEmergencyContact(data.emergencyContact)) ...[
                  const SizedBox(height: 16),
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

                const SizedBox(height: 24),

                // ── Bottom Edit Action Button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.editProfile);
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: Text(
                      l10n.editProfile,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.surfaceDarkElevated
                          : Colors.white,
                      foregroundColor: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Royal Blue Curved Hero Header (Matches Home / Leave Screen) ──
  Widget _buildRoyalHeroHeader(
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038B8), // Royal Blue Deep
            Color(0xFF0052FF), // Royal Blue Main
            Color(0xFF1E6BFF), // Royal Blue Light Glow
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x550052FF),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Translucent decorative background circles
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
              child: Column(
                children: [
                  // ── Top Navigation Bar ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showBackButton)
                        _frostedHeroButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => context.pop(),
                        )
                      else
                        const SizedBox(width: 40),
                      Text(
                        l10n.myProfile,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      _frostedHeroButton(
                        icon: Icons.edit_rounded,
                        tooltip: l10n.editProfile,
                        onTap: () => context.push(AppRoutes.editProfile),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Avatar with Illuminated White Ring & Camera Badge ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: data.photoUrl!,
                                  width: 90,
                                  height: 90,
                                  memCacheWidth: 250,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      _initials(displayName),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  child: Center(
                                    child: Text(
                                      _initials(displayName),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Floating Camera Edit Action Badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(AppRoutes.editProfile);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Full Display Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Khmer Name (if present)
                  if (data.khmerName != null && data.khmerName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.khmerName!.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Job Title / Role & Department
                  if (departmentRole.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      departmentRole,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Frosted Role & Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeroRoleBadge(data.roles),
                      const SizedBox(width: 8),
                      _buildHeroStatusBadge(isActive, data.employmentStatus ?? 'Active'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frostedHeroButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroRoleBadge(List<String> roles) {
    final roleText = roles.isNotEmpty ? roles.first.replaceAll('_', ' ') : 'Employee';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        roleText.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildHeroStatusBadge(bool isActive, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? const Color(0xFF34D399) : const Color(0xFFFBBF24))
                      .withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── High-Value Key Stats Strip ──
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
            icon: Icons.event_available_rounded,
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
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
                  fontSize: 11,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: isDark ? AppColors.grey500 : AppColors.grey400),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
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
