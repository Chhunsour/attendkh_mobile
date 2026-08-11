import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/admin_settings_repository.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

final adminSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return AdminSettingsRepository().getSettings();
});

/// Defaults used when the server doesn't provide a value.
const _defaults = <String, String>{
  'app_name': 'MPG HR',
  'support_email': 'support@example.com',
  'default_timezone': 'Asia/Phnom_Penh',
  'default_currency': 'USD',
};

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.platformSettingsTitle,
          style: const TextStyle(
            color: AppColors.grey800,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(adminSettingsProvider),
        child: settingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => _buildError(context, err, ref, l10n),
          data: (settings) =>
              _SettingsEditor(settings: settings, ref: ref),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object err, WidgetRef ref, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(l10n.failedToLoadSettings,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminSettingsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
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

  /// Holds the mutable local values.
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
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

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      // Build the payload — all values as strings
      final data = <String, String>{};
      for (final entry in _controllers.entries) {
        data[entry.key] = entry.value.text.trim();
      }

      await AdminSettingsRepository().updateSettings(data);
      widget.ref.invalidate(adminSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSavedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsFailed(e.toString())),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.grey500),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey800,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Global Settings ──
        _SectionTitle(title: l10n.globalSettingsTitle),
        const SizedBox(height: 16),
        _buildTextField('app_name', l10n.appNameLabel, Icons.app_shortcut_rounded),
        _buildTextField('support_email', l10n.supportEmailLabel, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
        _buildTextField('default_timezone', l10n.defaultTimezoneLabel, Icons.schedule_rounded),
        _buildTextField('default_currency', l10n.defaultCurrencyLabel, Icons.attach_money_rounded),

        const SizedBox(height: 24),

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
              _isSaving ? l10n.saving : l10n.saveSettings,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}