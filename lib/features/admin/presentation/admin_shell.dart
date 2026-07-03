import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/core/router/app_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_companies_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_announcements_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_audit_logs_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_support_tickets_screen.dart';
import 'package:mpg_hr_mobile_app/features/admin/presentation/admin_settings_screen.dart';

/// Shell for Super Admin navigation — drawer-based.
///
/// Uses [IndexedStack] with local state instead of ShellRoute + context.go()
/// to avoid the Flutter semantics bug (!semantics.parentDataDirty assertion)
/// that occurs when GoRouter tears down and rebuilds widget trees during
/// ShellRoute child swaps.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  static const initialTab = 'dashboard';

  /// Global key so child screens can open this shell's drawer.
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  String _activeTab = AdminShell.initialTab;

  static const _tabScreens = <String, Widget>{
    'dashboard': AdminDashboardScreen(),
    'companies': AdminCompaniesScreen(),
    'announcements': AdminAnnouncementsScreen(),
    'audit_logs': AdminAuditLogsScreen(),
    'support_tickets': AdminSupportTicketsScreen(),
    'settings': AdminSettingsScreen(),
  };

  void _navigateTo(String tab) {
    setState(() => _activeTab = tab);
    // Close drawer after navigation
    AdminShell.scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Super Admin';
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      key: AdminShell.scaffoldKey,
      body: IndexedStack(
        index: _tabScreens.keys.toList().indexOf(_activeTab),
        children: _tabScreens.values.toList(),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withAlpha(60),
                              AppColors.primary.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withAlpha(90),
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(90),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials.isNotEmpty ? initials : 'SA',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Inter',
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withAlpha(90)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_rounded,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                'Platform Administrator',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(230),
                                  fontFamily: 'Inter',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Menu Items ──────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                  children: [
                    _sectionLabel('PLATFORM'),
                    _AdminDrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      tab: 'dashboard',
                      isActive: _activeTab == 'dashboard',
                      onTap: () => _navigateTo('dashboard'),
                    ),
                    _AdminDrawerItem(
                      icon: Icons.business_rounded,
                      label: 'Companies',
                      tab: 'companies',
                      isActive: _activeTab == 'companies',
                      onTap: () => _navigateTo('companies'),
                    ),
                    _AdminDrawerItem(
                      icon: Icons.campaign_rounded,
                      label: 'Announcements',
                      tab: 'announcements',
                      isActive: _activeTab == 'announcements',
                      onTap: () => _navigateTo('announcements'),
                    ),
                    const SizedBox(height: 10),
                    _sectionLabel('MONITORING'),
                    _AdminDrawerItem(
                      icon: Icons.history_rounded,
                      label: 'Audit Logs',
                      tab: 'audit_logs',
                      isActive: _activeTab == 'audit_logs',
                      onTap: () => _navigateTo('audit_logs'),
                    ),
                    _AdminDrawerItem(
                      icon: Icons.support_agent_rounded,
                      label: 'Support Tickets',
                      tab: 'support_tickets',
                      isActive: _activeTab == 'support_tickets',
                      onTap: () => _navigateTo('support_tickets'),
                    ),
                    const SizedBox(height: 10),
                    _sectionLabel('CONFIGURATION'),
                    _AdminDrawerItem(
                      icon: Icons.tune_rounded,
                      label: 'Platform Settings',
                      tab: 'settings',
                      isActive: _activeTab == 'settings',
                      onTap: () => _navigateTo('settings'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, thickness: 1, color: AppColors.grey400.withAlpha(60)),
                    ),
                    _AdminDrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Switch to Company',
                      tab: 'switch',
                      isActive: false,
                      isSecondary: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.dashboard);
                      },
                    ),
                  ],
                ),
              ),

              // ── Logout ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.danger.withAlpha(45)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.logout_rounded, color: AppColors.danger, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
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
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.grey400,
          letterSpacing: 1.4,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tab;
  final bool isActive;
  final bool isSecondary;
  final VoidCallback onTap;

  const _AdminDrawerItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withAlpha(16) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: AppColors.primary.withAlpha(50))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withAlpha(28)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isActive
                        ? AppColors.primary
                        : isSecondary
                            ? AppColors.grey500
                            : AppColors.grey600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : isSecondary
                              ? AppColors.grey500
                              : AppColors.grey700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
