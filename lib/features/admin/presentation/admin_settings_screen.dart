import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Settings'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingSection(title: 'General', children: [
            _SettingTile(icon: Icons.language, title: 'Default Language', value: 'English'),
            _SettingTile(icon: Icons.schedule, title: 'Default Timezone', value: 'UTC+7 (Phnom Penh)'),
            _SettingTile(icon: Icons.attach_money, title: 'Default Currency', value: 'USD (\$)'),
          ]),
          const SizedBox(height: 16),
          _SettingSection(title: 'Registration', children: [
            _SettingTile(icon: Icons.person_add, title: 'Auto-approve Companies', value: 'Enabled'),
            _SettingTile(icon: Icons.email, title: 'Send Welcome Email', value: 'Enabled'),
            _SettingTile(icon: Icons.block, title: 'Registration Open', value: 'Enabled'),
          ]),
          const SizedBox(height: 16),
          _SettingSection(title: 'Security', children: [
            _SettingTile(icon: Icons.lock, title: 'Require Email Verification', value: 'Yes'),
            _SettingTile(icon: Icons.security, title: 'Enforce 2FA for Admins', value: 'No'),
            _SettingTile(icon: Icons.timer, title: 'Session Timeout', value: '8 hours'),
          ]),
          const SizedBox(height: 16),
          _SettingSection(title: 'Notifications', children: [
            _SettingTile(icon: Icons.notifications, title: 'New Company Alert', value: 'Enabled'),
            _SettingTile(icon: Icons.report, title: 'Suspicious Activity Alert', value: 'Enabled'),
            _SettingTile(icon: Icons.support, title: 'New Ticket Notification', value: 'Enabled'),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(value, style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
      onTap: () {},
      shape: const Border(),
    );
  }
}