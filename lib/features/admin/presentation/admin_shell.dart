import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

/// Shell for Super Admin navigation — drawer-based
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: const Center(
                        child: Text('SA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Super Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Platform Management', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(179))),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _AdminDrawerItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      route: '/admin/dashboard',
                    ),
                    _AdminDrawerItem(
                      icon: Icons.business_outlined,
                      label: 'Companies',
                      route: '/admin/companies',
                    ),
                    _AdminDrawerItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      route: '/admin/announcements',
                    ),
                    _AdminDrawerItem(
                      icon: Icons.history_outlined,
                      label: 'Audit Logs',
                      route: '/admin/audit-logs',
                    ),
                    _AdminDrawerItem(
                      icon: Icons.support_outlined,
                      label: 'Support Tickets',
                      route: '/admin/support-tickets',
                    ),
                    _AdminDrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      route: '/admin/settings',
                    ),
                    const Divider(height: 32),
                    _AdminDrawerItem(
                      icon: Icons.switch_account_outlined,
                      label: 'Switch to Company',
                      route: '/main/dashboard',
                    ),
                  ],
                ),
              ),

              // Logout
              Padding(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    // TODO: logout
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _AdminDrawerItem({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.grey600, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.grey700)),
        onTap: () {
          context.go(route);
          Navigator.pop(context); // close drawer
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: GoRouterState.of(context).matchedLocation == route,
        selectedTileColor: AppColors.primary.withAlpha(20),
        selectedColor: AppColors.primary,
      ),
    );
  }
}