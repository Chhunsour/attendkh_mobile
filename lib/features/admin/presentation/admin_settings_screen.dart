import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/admin/data/admin_settings_repository.dart';

final adminSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return AdminSettingsRepository().getSettings();
});

/// Keys that should be rendered as toggle switches (boolean values).
/// All other keys render as text fields.
const _booleanSettingKeys = {
  'auto_approve_companies',
  'send_welcome_email',
  'registration_open',
  'require_email_verification',
  'enforce_2fa',
  'new_company_alert',
  'suspicious_activity_alert',
  'new_ticket_notification',
};

/// Defaults used when the server doesn't provide a value.
const _defaults = <String, String>{
  'language': 'English',
  'timezone': 'UTC+7',
  'currency': 'USD',
  'session_timeout': '8',
};

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);

    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Platform Settings',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(adminSettingsProvider),
            child: settingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => _buildError(context, err, ref),
              data: (settings) =>
                  _SettingsEditor(settings: settings, ref: ref),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load settings',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminSettingsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Settings Editor (Stateful — manages local edits)
// ══════════════════════════════════════════════════════════════════════════════
class _SettingsEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic> settings;
  final WidgetRef ref;

  const _SettingsEditor({required this.settings, required this.ref});

  @override
  ConsumerState<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends ConsumerState<_SettingsEditor> {
  bool _isSaving = false;

  /// Holds the mutable local values.  String keys → TextEditingControllers,
  /// boolean keys → plain bool stored directly in [_boolValues].
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _boolValues;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _boolValues = {};

    // Populate from server data
    for (final key in _booleanSettingKeys) {
      final raw = widget.settings[key];
      _boolValues[key] = _parseBool(raw, _defaults[key] == 'true');
    }
  }

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      final defaultVal = _defaults[key] ?? '';
      _controllers[key] = TextEditingController(
        text: (widget.settings[key] ?? defaultVal).toString(),
      );
    }
    return _controllers[key]!;
  }

  bool _parseBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return fallback;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      // Build the payload — all values as strings
      final data = <String, String>{};
      for (final entry in _controllers.entries) {
        data[entry.key] = entry.value.text.trim();
      }
      for (final entry in _boolValues.entries) {
        data[entry.key] = entry.value.toString();
      }

      await AdminSettingsRepository().updateSettings(data);
      widget.ref.invalidate(adminSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Text field for string/numeric settings ─────────────────────────────────
  Widget _buildTextField(String key, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    final ctrl = _getController(key);
    return _SettingsRow(
      icon: icon,
      label: label,
      trailing: SizedBox(
        width: 130,
        child: TextFormField(
          controller: ctrl,
          textAlign: TextAlign.end,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  // ── Switch toggle for boolean settings ────────────────────────────────────
  Widget _buildSwitch(String key, String label, IconData icon) {
    final value = _boolValues[key] ?? false;
    return _SettingsRow(
      icon: icon,
      label: label,
      trailing: SizedBox(
        height: 28,
        child: Switch(
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _boolValues[key] = v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── General ──
        _SectionTitle(title: 'General'),
        const SizedBox(height: 8),
        _buildTextField('language', 'Default Language', Icons.language_rounded),
        _buildTextField('timezone', 'Default Timezone', Icons.schedule_rounded),
        _buildTextField(
          'currency',
          'Default Currency',
          Icons.attach_money_rounded,
        ),

        const SizedBox(height: 24),

        // ── Registration ──
        _SectionTitle(title: 'Registration'),
        const SizedBox(height: 8),
        _buildSwitch(
          'auto_approve_companies',
          'Auto-approve Companies',
          Icons.person_add_rounded,
        ),
        _buildSwitch(
          'send_welcome_email',
          'Send Welcome Email',
          Icons.email_rounded,
        ),
        _buildSwitch(
          'registration_open',
          'Registration Open',
          Icons.app_registration_rounded,
        ),

        const SizedBox(height: 24),

        // ── Security ──
        _SectionTitle(title: 'Security'),
        const SizedBox(height: 8),
        _buildSwitch(
          'require_email_verification',
          'Require Email Verification',
          Icons.verified_user_rounded,
        ),
        _buildSwitch(
          'enforce_2fa',
          'Enforce 2FA for Admins',
          Icons.security_rounded,
        ),
        _buildTextField(
          'session_timeout',
          'Session Timeout (hours)',
          Icons.timer_rounded,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 24),

        // ── Notifications ──
        _SectionTitle(title: 'Notifications'),
        const SizedBox(height: 8),
        _buildSwitch(
          'new_company_alert',
          'New Company Alert',
          Icons.notifications_active_rounded,
        ),
        _buildSwitch(
          'suspicious_activity_alert',
          'Suspicious Activity Alert',
          Icons.report_rounded,
        ),
        _buildSwitch(
          'new_ticket_notification',
          'New Ticket Notification',
          Icons.confirmation_number_rounded,
        ),

        const SizedBox(height: 28),

        // ── Save Button ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Settings',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Reusable row widget
// ══════════════════════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.grey100)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.grey500, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey800,
            fontFamily: 'Inter',
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Section title
// ══════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.grey500,
          letterSpacing: 0.5,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}