import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:attendkh/providers/auth_provider.dart';
import 'package:attendkh/providers/profile_provider.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/services/profile_repository.dart';
import 'package:attendkh/utils/image_compressor.dart';
import 'package:attendkh/l10n/app_localizations.dart';

/// One cut corner on every card — the motif the admin surfaces share.
const _cardShape = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(20),
  bottomRight: Radius.circular(20),
  bottomLeft: Radius.circular(6),
);
const _chipShape = BorderRadius.only(
  topLeft: Radius.circular(14),
  topRight: Radius.circular(14),
  bottomRight: Radius.circular(14),
  bottomLeft: Radius.circular(5),
);

class CompanyOwnerProfileScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const CompanyOwnerProfileScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<CompanyOwnerProfileScreen> createState() =>
      _CompanyOwnerProfileScreenState();
}

class _CompanyOwnerProfileScreenState
    extends ConsumerState<CompanyOwnerProfileScreen> {
  final _formKeyProfile = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String? _gender;
  String? _maritalStatus;
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
        _maritalStatus = profile.maritalStatus;
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
        maritalStatus: _maritalStatus,
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

  // Closed by default — a change-password form does not belong open on a
  // page you visit to read your own details.
  bool _showPasswordForm = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            centerTitle: true,
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
                ),
                child: Stack(
                  children: [
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
                    Positioned.fill(
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        backgroundImage: _photo != null
                                            ? FileImage(_photo!)
                                            : (profileAsync.value?.photoUrl !=
                                                          null
                                                      ? CachedNetworkImageProvider(
                                                          profileAsync
                                                              .value!
                                                              .photoUrl!,
                                                        )
                                                      : null)
                                                  as ImageProvider?,
                                        child:
                                            (_photo == null &&
                                                profileAsync.value?.photoUrl ==
                                                    null)
                                            ? Text(
                                                _initials(
                                                  authState.userName ?? 'O',
                                                ),
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
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.20,
                                              ),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              authState.userName ?? 'Company Owner',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (authState.userEmail != null &&
                                authState.userEmail!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                authState.userEmail!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.business_center_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.roleCompanyOwner,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
                  ],
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
                              l10n.maritalStatusLabel,
                              DropdownButtonFormField<String>(
                                initialValue: _maritalStatus,
                                decoration: _inputDecoration(),
                                items: [
                                  DropdownMenuItem(
                                    value: 'single',
                                    child: Text(l10n.maritalSingle),
                                  ),
                                  DropdownMenuItem(
                                    value: 'married',
                                    child: Text(l10n.maritalMarried),
                                  ),
                                  DropdownMenuItem(
                                    value: 'divorced',
                                    child: Text(l10n.maritalDivorced),
                                  ),
                                  DropdownMenuItem(
                                    value: 'widowed',
                                    child: Text(l10n.maritalWidowed),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _maritalStatus = val),
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
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: _chipShape,
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
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: _chipShape,
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
                            if (_maritalStatus != null)
                              _buildInfoRow(
                                Icons.favorite_rounded,
                                l10n.maritalStatusLabel,
                                _maritalStatus == 'single'
                                    ? l10n.maritalSingle
                                    : _maritalStatus == 'married'
                                    ? l10n.maritalMarried
                                    : _maritalStatus == 'divorced'
                                    ? l10n.maritalDivorced
                                    : l10n.maritalWidowed,
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
                    expanded: _showPasswordForm,
                    onHeaderTap: () =>
                        setState(() => _showPasswordForm = !_showPasswordForm),
                    child: Form(
                      key: _formKeyPassword,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            l10n.currentPasswordLabel,
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _hideCurrent,
                              validator: (v) =>
                                  v!.isEmpty ? l10n.fieldRequired : null,
                              decoration: _passwordDecoration(
                                _hideCurrent,
                                () => setState(
                                  () => _hideCurrent = !_hideCurrent,
                                ),
                              ),
                            ),
                          ),
                          _buildField(
                            l10n.newPasswordLabel,
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _hideNew,
                              validator: (v) {
                                if (v!.isEmpty) return l10n.fieldRequired;
                                if (v.length < 8) return l10n.min8Chars;
                                return null;
                              },
                              decoration: _passwordDecoration(
                                _hideNew,
                                () => setState(() => _hideNew = !_hideNew),
                              ),
                            ),
                          ),
                          _buildField(
                            l10n.confirmPasswordLabel,
                            TextFormField(
                              controller: _passwordConfirmController,
                              obscureText: _hideConfirm,
                              validator: (v) {
                                if (v!.isEmpty) return l10n.fieldRequired;
                                if (v != _passwordController.text) {
                                  return l10n.passwordsDoNotMatch;
                                }
                                return null;
                              },
                              decoration: _passwordDecoration(
                                _hideConfirm,
                                () => setState(
                                  () => _hideConfirm = !_hideConfirm,
                                ),
                              ),
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
                                shape: const RoundedRectangleBorder(
                                  borderRadius: _chipShape,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
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
    VoidCallback? onHeaderTap,
    bool expanded = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final header = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primaryLight,
            borderRadius: _chipShape,
          ),
          child: Icon(
            icon,
            color: isDark ? const Color(0xFF93C5FD) : AppColors.primary,
            size: 20,
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
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        if (onHeaderTap != null)
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.grey400,
            ),
          ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: _cardShape,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onHeaderTap == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: header,
            )
          else
            InkWell(
              onTap: onHeaderTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, expanded ? 0 : 18),
                child: header,
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, Widget field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
          ),
          field,
        ],
      ),
    );
  }

  /// Label left, value right, hairline between — a grey icon box per row
  /// added weight without adding meaning.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.grey400, size: 16),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: AppColors.border(context)),
      ],
    );
  }

  InputDecoration _passwordDecoration(bool hidden, VoidCallback onToggle) {
    return _inputDecoration().copyWith(
      suffixIcon: IconButton(
        onPressed: onToggle,
        splashRadius: 18,
        icon: Icon(
          hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 18,
          color: AppColors.grey500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDarkElevated
          : AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
