import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/providers/auth_provider.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/components/dialogs/logout_dialog.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/providers/locale_provider.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const AdminProfileScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _formKeyProfile = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String? _gender;
  DateTime? _dateOfBirth;

  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _isEditing = false;

  File? _photo;

  late final ProfileRepository _profileRepo;

  @override
  void initState() {
    super.initState();
    _profileRepo = ProfileRepository();

    final auth = ref.read(authProvider);
    _nameController = TextEditingController(text: auth.userName ?? '');
    _emailController = TextEditingController(text: auth.userEmail ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _profileRepo.getProfile();
      if (!mounted) return;
      setState(() {
        _phoneController.text = profile.phone ?? '';
        _addressController.text = profile.address ?? '';
        _gender = profile.gender;
        if (profile.dateOfBirth != null) {
          _dateOfBirth = DateTime.tryParse(profile.dateOfBirth!);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressed = await ImageCompressor.compressToWebp(pickedFile.path);
      setState(() => _photo = compressed);
    }
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _saveProfile() async {
    if (!_formKeyProfile.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      final String phone = _phoneController.text.trim();
      await _profileRepo.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone.isNotEmpty ? phone : null,
        gender: _gender,
        dateOfBirth: _dateOfBirth != null
            ? "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}"
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        photo: _photo,
      );

      await ref.read(authProvider.notifier).checkAuthStatus();
      ref.invalidate(profileProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdatedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    setState(() => _isSavingPassword = true);
    try {
      await _profileRepo.updatePassword(
        currentPassword: _currentPasswordController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );

      if (mounted) {
        _currentPasswordController.clear();
        _passwordController.clear();
        _passwordConfirmController.clear();

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordUpdatedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Text(
              l10n.profileSettingsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    l10n.editProfile,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withAlpha(30),
                            backgroundImage: _photo != null
                                ? FileImage(_photo!)
                                : (profileAsync.value?.photoUrl != null
                                          ? CachedNetworkImageProvider(
                                              profileAsync.value!.photoUrl!,
                                            )
                                          : null)
                                      as ImageProvider?,
                            child:
                                (_photo == null &&
                                    profileAsync.value?.photoUrl == null)
                                ? Text(
                                    _initials(authState.userName ?? 'A'),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authState.userName ?? 'Super Admin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authState.userEmail ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Super Admin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCard(
                    icon: Icons.person_outline_rounded,
                    title: l10n.profileInfoTitle,
                    subtitle: l10n.profileInfoDesc,
                    child: Form(
                      key: _formKeyProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing) ...[
                            _buildField(
                              l10n.nameLabel,
                              TextFormField(
                                controller: _nameController,
                                validator: (v) => v!.trim().isEmpty
                                    ? l10n.fieldRequired
                                    : null,
                                decoration: _inputDecoration(),
                              ),
                            ),
                            _buildField(
                              l10n.emailLabel,
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => v!.trim().isEmpty
                                    ? l10n.fieldRequired
                                    : null,
                                decoration: _inputDecoration(),
                              ),
                            ),
                            _buildField(
                              l10n.phoneLabel,
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(),
                              ),
                            ),
                            _buildField(
                              l10n.genderLabel,
                              DropdownButtonFormField<String>(
                                initialValue: _gender,
                                decoration: _inputDecoration(),
                                items: [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text(l10n.genderMale),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text(l10n.genderFemale),
                                  ),
                                  DropdownMenuItem(
                                    value: 'other',
                                    child: Text(l10n.genderOther),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _gender = val),
                              ),
                            ),
                            _buildField(
                              l10n.dateOfBirthLabel,
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dateOfBirth ?? DateTime(2000),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            onSurface: AppColors.grey900,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _dateOfBirth = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: _inputDecoration().copyWith(
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                  child: Text(
                                    _dateOfBirth != null
                                        ? "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}"
                                        : l10n.selectDate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _dateOfBirth != null
                                          ? AppColors.grey800
                                          : AppColors.grey500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildField(
                              l10n.addressLabel,
                              TextFormField(
                                controller: _addressController,
                                maxLines: 3,
                                decoration: _inputDecoration(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.grey300,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.cancel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isSavingProfile
                                          ? null
                                          : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isSavingProfile
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              l10n.saveProfileBtn,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildInfoRow(
                              Icons.person_rounded,
                              l10n.nameLabel,
                              _nameController.text,
                            ),
                            _buildInfoRow(
                              Icons.email_rounded,
                              l10n.emailLabel,
                              _emailController.text,
                            ),
                            if (_phoneController.text.isNotEmpty)
                              _buildInfoRow(
                                Icons.phone_rounded,
                                l10n.phoneLabel,
                                _phoneController.text,
                              ),
                            if (_gender != null)
                              _buildInfoRow(
                                Icons.wc_rounded,
                                l10n.genderLabel,
                                _gender == 'male'
                                    ? l10n.genderMale
                                    : _gender == 'female'
                                    ? l10n.genderFemale
                                    : l10n.genderOther,
                              ),
                            if (_dateOfBirth != null)
                              _buildInfoRow(
                                Icons.cake_rounded,
                                l10n.dateOfBirthLabel,
                                "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}",
                              ),
                            if (_addressController.text.isNotEmpty)
                              _buildInfoRow(
                                Icons.location_on_rounded,
                                l10n.addressLabel,
                                _addressController.text,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    icon: Icons.lock_outline_rounded,
                    title: l10n.updatePasswordTitle,
                    subtitle: l10n.updatePasswordDesc,
                    child: Form(
                      key: _formKeyPassword,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            l10n.currentPasswordLabel,
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              validator: (v) =>
                                  v!.isEmpty ? l10n.fieldRequired : null,
                              decoration: _inputDecoration(),
                            ),
                          ),
                          _buildField(
                            l10n.newPasswordLabel,
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              validator: (v) {
                                if (v!.isEmpty) return l10n.fieldRequired;
                                if (v.length < 8) return l10n.min8Chars;
                                return null;
                              },
                              decoration: _inputDecoration(),
                            ),
                          ),
                          _buildField(
                            l10n.confirmPasswordLabel,
                            TextFormField(
                              controller: _passwordConfirmController,
                              obscureText: true,
                              validator: (v) {
                                if (v!.isEmpty) return l10n.fieldRequired;
                                if (v != _passwordController.text) {
                                  return l10n.passwordsDoNotMatch;
                                }
                                return null;
                              },
                              decoration: _inputDecoration(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSavingPassword
                                  ? null
                                  : _savePassword,
                              icon: _isSavingPassword
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.lock_rounded, size: 20),
                              label: Text(
                                _isSavingPassword
                                    ? l10n.saving
                                    : l10n.btnUpdatePassword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.grey800,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    icon: Icons.tune_rounded,
                    title: l10n.accessRoles,
                    subtitle: 'Language & settings',
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.language_rounded,
                          title: l10n.language,
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ref.watch(localeProvider).languageCode,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.grey500,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey800,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text(l10n.english),
                                ),
                                DropdownMenuItem(
                                  value: 'km',
                                  child: Text(l10n.khmer),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  ref
                                      .read(localeProvider.notifier)
                                      .setLocale(Locale(newValue));
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger.withAlpha(30)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showLogoutConfirmation(context, ref),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                l10n.logOut,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.danger,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
          ),
          field,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.grey500, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey500,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.grey600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey800,
                ),
              ),
            ),
            ?trailing,
            if (onTap != null && trailing == null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.grey400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
