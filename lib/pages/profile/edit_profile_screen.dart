import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mpg_hr_mobile_app/providers/profile_provider.dart';
import 'package:mpg_hr_mobile_app/services/profile_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _fullNameCtrl;
  late TextEditingController _khmerNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  String? _gender;
  String? _maritalStatus;
  DateTime? _dateOfBirth;
  File? _photo;
  bool _isLoading = false;

  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _emergencyContactNameCtrl;
  late TextEditingController _emergencyContactRelationshipCtrl;
  late TextEditingController _emergencyContactPhoneCtrl;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _khmerNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _bankNameCtrl = TextEditingController();
    _bankAccountCtrl = TextEditingController();
    _emergencyContactNameCtrl = TextEditingController();
    _emergencyContactRelationshipCtrl = TextEditingController();
    _emergencyContactPhoneCtrl = TextEditingController();
  }

  void _populateData(ProfileData data) {
    if (_fullNameCtrl.text.isEmpty && _khmerNameCtrl.text.isEmpty && !mounted) {
      return;
    }

    _fullNameCtrl.text = data.fullName ?? data.name;
    _khmerNameCtrl.text = data.khmerName ?? '';
    _emailCtrl.text = data.email ?? '';
    _phoneCtrl.text = data.phone ?? '';

    _gender = data.gender;
    _maritalStatus = data.maritalStatus;
    if (data.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(data.dateOfBirth!);
    }

    _bankNameCtrl.text = data.bankName ?? '';
    _bankAccountCtrl.text = data.bankAccount ?? '';

    if (data.emergencyContact != null) {
      _emergencyContactNameCtrl.text =
          data.emergencyContact!['name']?.toString() ?? '';
      _emergencyContactRelationshipCtrl.text =
          data.emergencyContact!['relationship']?.toString() ?? '';
      _emergencyContactPhoneCtrl.text =
          data.emergencyContact!['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _khmerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactRelationshipCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
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

  Future<void> _selectDateOfBirth() async {
    final initialDate = _dateOfBirth ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.grey900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = ProfileRepository();

      final String fullName = _fullNameCtrl.text.trim();
      final String khmerName = _khmerNameCtrl.text.trim();
      final String displayName = [fullName, khmerName].where((s) => s.isNotEmpty).join(' ');
      final String phone = _phoneCtrl.text.trim();

      await repo.updateProfile(
        name: displayName.isNotEmpty ? displayName : null,
        fullName: fullName.isNotEmpty ? fullName : null,
        khmerName: khmerName.isNotEmpty ? khmerName : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: phone.isNotEmpty ? phone : null,
        gender: _gender,
        dateOfBirth: _dateOfBirth != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
            : null,
        maritalStatus: _maritalStatus,
        bankName: _bankNameCtrl.text.trim().isNotEmpty
            ? _bankNameCtrl.text.trim()
            : null,
        bankAccount: _bankAccountCtrl.text.trim().isNotEmpty
            ? _bankAccountCtrl.text.trim()
            : null,
        emergencyContactName: _emergencyContactNameCtrl.text.trim().isNotEmpty
            ? _emergencyContactNameCtrl.text.trim()
            : null,
        emergencyContactRelationship:
            _emergencyContactRelationshipCtrl.text.trim().isNotEmpty
            ? _emergencyContactRelationshipCtrl.text.trim()
            : null,
        emergencyContactPhone: _emergencyContactPhoneCtrl.text.trim().isNotEmpty
            ? _emergencyContactPhoneCtrl.text.trim()
            : null,
        photo: _photo,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdatedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdate}: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grey900,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.editProfile,
          style: const TextStyle(
            color: AppColors.grey900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _save,
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.grey200.withValues(alpha: 0.8))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.save,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      body: profileAsync.when(
        data: (data) {
          if (_fullNameCtrl.text.isEmpty &&
              _khmerNameCtrl.text.isEmpty &&
              data.name.isNotEmpty) {
            _populateData(data);
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Photo Section ──
                _buildPhotoPicker(data),

                const SizedBox(height: 20),

                // ── Personal Info Card ──
                _buildSectionCard(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: l10n.profileInfoTitle,
                  children: [
                    _buildInputField(
                      label: 'Full Name (Latin)',
                      controller: _fullNameCtrl,
                      icon: Icons.person_rounded,
                    ),
                    _buildInputField(
                      label: 'Khmer Name (ឈ្មោះជាភាសាខ្មែរ)',
                      controller: _khmerNameCtrl,
                      icon: Icons.badge_outlined,
                    ),
                    _buildInputField(
                      label: l10n.phoneLabel,
                      controller: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputField(
                      label: l10n.emailLabel,
                      controller: _emailCtrl,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: l10n.genderLabel,
                            value: _gender,
                            icon: Icons.wc_rounded,
                            items: [
                              DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                              DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                              DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
                            ],
                            onChanged: (val) => setState(() => _gender = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Marital Status',
                            value: _maritalStatus,
                            icon: Icons.favorite_border_rounded,
                            items: const [
                              DropdownMenuItem(value: 'single', child: Text('Single')),
                              DropdownMenuItem(value: 'married', child: Text('Married')),
                              DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                              DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                            ],
                            onChanged: (val) => setState(() => _maritalStatus = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDatePickerField(
                      label: 'Date of Birth',
                      value: _dateOfBirth,
                      icon: Icons.cake_outlined,
                      onTap: _selectDateOfBirth,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Banking Card ──
                _buildSectionCard(
                  icon: Icons.account_balance_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Financial & Banking',
                  children: [
                    _buildInputField(
                      label: 'Bank Name',
                      controller: _bankNameCtrl,
                      icon: Icons.account_balance_rounded,
                    ),
                    _buildInputField(
                      label: 'Bank Account Number',
                      controller: _bankAccountCtrl,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Emergency Contact Card ──
                _buildSectionCard(
                  icon: Icons.emergency_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Emergency Contact',
                  children: [
                    _buildInputField(
                      label: 'Contact Name',
                      controller: _emergencyContactNameCtrl,
                      icon: Icons.person_outline_rounded,
                    ),
                    _buildInputField(
                      label: 'Relationship',
                      controller: _emergencyContactRelationshipCtrl,
                      icon: Icons.people_outline_rounded,
                    ),
                    _buildInputField(
                      label: 'Emergency Phone',
                      controller: _emergencyContactPhoneCtrl,
                      icon: Icons.phone_in_talk_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingProfile),
        error: (e, _) => Center(child: Text('${l10n.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildPhotoPicker(ProfileData data) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _photo != null
                        ? Image.file(
                            _photo!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                        : (data.photoUrl != null && data.photoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: data.photoUrl!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.grey400,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.grey400,
                              )),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap avatar to change photo',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.grey900),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
          filled: true,
          fillColor: AppColors.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey900),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final displayStr = value != null ? DateFormat('yyyy-MM-dd').format(value) : 'Select date';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.grey400),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value != null ? AppColors.grey900 : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
