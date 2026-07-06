import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/utils/router/app_router.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_dashboard_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_companies_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_announcements_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_audit_logs_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_support_tickets_screen.dart';
import 'package:mpg_hr_mobile_app/pages/super_admin/admin_settings_screen.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  static const initialTab = 'dashboard';

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;
  String _activeTab = AdminShell.initialTab;

  final List<String> _mainTabs = ['dashboard', 'companies', 'support_tickets'];

  static const _tabScreens = <String, Widget>{
    'dashboard': AdminDashboardScreen(),
    'companies': AdminCompaniesScreen(),
    'support_tickets': AdminSupportTicketsScreen(),
    'announcements': AdminAnnouncementsScreen(),
    'audit_logs': AdminAuditLogsScreen(),
    'settings': AdminSettingsScreen(),
  };

  void _onTabTapped(int index) {
    if (index == 3) {
      _showMoreBottomSheet();
      return;
    }
    setState(() {
      _currentIndex = index;
      _activeTab = _mainTabs[index];
    });
  }

  void _navigateTo(String tab) {
    setState(() {
      _activeTab = tab;
      if (_mainTabs.contains(tab)) {
        _currentIndex = _mainTabs.indexOf(tab);
      } else {
        _currentIndex = 3;
      }
    });
  }

  void _showMoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreMenuBottomSheet(
        activeTab: _activeTab,
        onNavigate: (tab) {
          Navigator.pop(context);
          _navigateTo(tab);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabScreens.keys.toList().indexOf(_activeTab),
        children: _tabScreens.entries.map((e) {
          return ExcludeSemantics(
            excluding: e.key != _activeTab,
            child: e.value,
          );
        }).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withAlpha(30),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded, color: AppColors.primary),
            label: 'Companies',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded, color: AppColors.primary),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreMenuBottomSheet extends ConsumerWidget {
  final String activeTab;
  final Function(String) onNavigate;

  const _MoreMenuBottomSheet({
    required this.activeTab,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Super Admin';
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            // User Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context); // close bottom sheet
                    context.push(AppRoutes.adminProfile);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withAlpha(20),
                          child: Text(
                            initials.isNotEmpty ? initials : 'SA',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Platform Administrator', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
            
            // Menu Items
            _MoreMenuItem(
              icon: Icons.campaign_rounded,
              label: 'Announcements',
              isActive: activeTab == 'announcements',
              onTap: () => onNavigate('announcements'),
            ),
            _MoreMenuItem(
              icon: Icons.history_rounded,
              label: 'Audit Logs',
              isActive: activeTab == 'audit_logs',
              onTap: () => onNavigate('audit_logs'),
            ),
            _MoreMenuItem(
              icon: Icons.tune_rounded,
              label: 'Platform Settings',
              isActive: activeTab == 'settings',
              onTap: () => onNavigate('settings'),
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            
            // Switch & Logout
            _MoreMenuItem(
              icon: Icons.swap_horiz_rounded,
              label: 'Switch to Company',
              iconColor: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.dashboard);
              },
            ),
            _MoreMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              onTap: () async {
                // DO NOT Navigator.pop(context) first, as it invalidates the context
                // needed for showLogoutConfirmation's dialog.
                await showLogoutConfirmation(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : (iconColor ?? Colors.grey[700]);
    final txtColor = isActive ? AppColors.primary : (textColor ?? Colors.black87);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        color: isActive ? AppColors.primary.withAlpha(10) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
