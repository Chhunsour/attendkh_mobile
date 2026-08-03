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
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
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
    // Initialize with empty controllers first to avoid null errors during first frame
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _bankNameCtrl = TextEditingController();
    _bankAccountCtrl = TextEditingController();
    _emergencyContactNameCtrl = TextEditingController();
    _emergencyContactRelationshipCtrl = TextEditingController();
    _emergencyContactPhoneCtrl = TextEditingController();
    
    // We will populate data in a post-frame callback or by watching the provider
  }

  void _populateData(ProfileData data) {
    if (_firstNameCtrl.text.isEmpty && _lastNameCtrl.text.isEmpty && !mounted) return;
    
    final names = (data.name).split(' ');
    final firstName = names.isNotEmpty ? names.first : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
    
    _firstNameCtrl.text = firstName;
    _lastNameCtrl.text = lastName;
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
      _emergencyContactNameCtrl.text = data.emergencyContact!['name']?.toString() ?? '';
      _emergencyContactRelationshipCtrl.text = data.emergencyContact!['relationship']?.toString() ?? '';
      _emergencyContactPhoneCtrl.text = data.emergencyContact!['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
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

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final repo = ProfileRepository();
      
      final String firstName = _firstNameCtrl.text.trim();
      final String lastName = _lastNameCtrl.text.trim();
      final String fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
      
      final String phone = _phoneCtrl.text.trim();
      
      await repo.updateProfile(
        name: fullName.isNotEmpty ? fullName : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: phone.isNotEmpty ? phone : null,
        gender: _gender,
        dateOfBirth: _dateOfBirth != null ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!) : null,
        maritalStatus: _maritalStatus,
        bankName: _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : null,
        bankAccount: _bankAccountCtrl.text.trim().isNotEmpty ? _bankAccountCtrl.text.trim() : null,
        emergencyContactName: _emergencyContactNameCtrl.text.trim().isNotEmpty ? _emergencyContactNameCtrl.text.trim() : null,
        emergencyContactRelationship: _emergencyContactRelationshipCtrl.text.trim().isNotEmpty ? _emergencyContactRelationshipCtrl.text.trim() : null,
        emergencyContactPhone: _emergencyContactPhoneCtrl.text.trim().isNotEmpty ? _emergencyContactPhoneCtrl.text.trim() : null,
        photo: _photo,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdatedSuccess), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToUpdate}: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildOutlinedField(String label, TextEditingController controller, {TextInputType? keyboardType, Widget? prefixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: prefixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.success, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.editProfile,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.success, size: 28),
              onPressed: _save,
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success),
              ),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (data) {
          // Initialize controllers with data if they are empty
          if (_firstNameCtrl.text.isEmpty && _lastNameCtrl.text.isEmpty && data.name.isNotEmpty) {
             _populateData(data);
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.grey200,
                            backgroundImage: _photo != null
                                ? FileImage(_photo!)
                                : (data.photoUrl != null ? NetworkImage(data.photoUrl!) : null)
                                    as ImageProvider?,
                            child: (_photo == null && data.photoUrl == null)
                                ? const Icon(Icons.person, size: 50, color: AppColors.grey400)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.grey200, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.profileInfoTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildOutlinedField(l10n.firstName, _firstNameCtrl),
                  _buildOutlinedField(l10n.lastName, _lastNameCtrl),
                  
                  // Phone with country code
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.phoneLabel,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.success, width: 2),
                        ),
                        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),

                  _buildOutlinedField(l10n.emailLabel, _emailCtrl, keyboardType: TextInputType.emailAddress),
                  
                  // Gender Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: l10n.genderLabel,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.success, width: 2),
                        ),
                        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                        DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                        DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
                      ],
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                  ),

                  // Marital Status Dropdown
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
                      decoration: InputDecoration(
                        labelText: 'Marital Status',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.success, width: 2),
                        ),
                        labelStyle: const TextStyle(color: AppColors.grey500, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'single', child: Text('Single')),
                        DropdownMenuItem(value: 'married', child: Text('Married')),
                        DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                        DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                      ],
                      onChanged: (val) => setState(() => _maritalStatus = val),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Financial & Banking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildOutlinedField('Bank Name', _bankNameCtrl),
                  _buildOutlinedField('Bank Account Number', _bankAccountCtrl),

                  const SizedBox(height: 16),
                  const Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 16),
                  _buildOutlinedField('Contact Name', _emergencyContactNameCtrl),
                  _buildOutlinedField('Relationship', _emergencyContactRelationshipCtrl),
                  _buildOutlinedField('Phone Number', _emergencyContactPhoneCtrl, keyboardType: TextInputType.phone),

                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => LoadingIndicator(message: l10n.loadingProfile),
        error: (e, _) => Center(child: Text('${l10n.errorPrefix}$e')),
      ),
    );
  }
}
