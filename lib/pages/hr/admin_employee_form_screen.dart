import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/utils/image_compressor.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

InputDecoration _fieldDecor(
  String label, {
  IconData? icon,
  Widget? suffixIcon,
  BuildContext? context,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null
        ? Icon(icon, size: 18, color: AppColors.grey400)
        : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context != null ? AppColors.surface(context) : AppColors.surfaceLight,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: TextStyle(fontSize: 14, color: AppColors.grey500),
    floatingLabelStyle: TextStyle(
      fontSize: 12,
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminEmployeeFormScreen extends ConsumerStatefulWidget {
  final EmployeeData? employee;
  const AdminEmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<AdminEmployeeFormScreen> createState() =>
      _AdminEmployeeFormScreenState();
}

class _AdminEmployeeFormScreenState
    extends ConsumerState<AdminEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _pickedPhoto;

  // Personal
  late TextEditingController _fullNameCtrl;
  late TextEditingController _khmerNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _nationalIdCtrl;
  late TextEditingController _addressCtrl;
  String? _gender;
  DateTime? _dateOfBirth;
  String? _maritalStatus;
  List<TextEditingController> _phoneNumberCtrls = [];
  final List<File> _pickedNationalIdImages = [];

  // Employment
  late TextEditingController _hireDateCtrl;
  late TextEditingController _probationEndCtrl;
  late TextEditingController _terminationDateCtrl;
  String? _employmentType;
  String? _employmentStatus;
  String? _role;
  int? _departmentId;
  int? _positionId;
  int? _branchId;
  int? _teamId;
  int? _managerId;
  late TextEditingController _notesCtrl;

  // Payroll
  late TextEditingController _salaryCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountCtrl;

  // Emergency
  late TextEditingController _emergNameCtrl;
  late TextEditingController _emergRelCtrl;
  late TextEditingController _emergPhoneCtrl;

  late TextEditingController _employeeIdCtrl;

  // System Access
  bool _createAccount = true;
  bool _showPassword = false;
  late TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;

    // Personal
    _fullNameCtrl = TextEditingController(text: e?.fullName ?? e?.name ?? '');
    _khmerNameCtrl = TextEditingController(text: e?.khmerName ?? '');
    _employeeIdCtrl = TextEditingController(text: e?.employeeId ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _nationalIdCtrl = TextEditingController(text: e?.nationalId ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _gender = e?.gender;
    _maritalStatus = e?.maritalStatus;
    if (e?.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(e!.dateOfBirth!);
    }
    // Additional phone numbers
    _phoneNumberCtrls = (e?.phoneNumbers ?? [])
        // ignore: avoid_types_as_parameter_names
        .map((num) => TextEditingController(text: num))
        .toList();

    // Employment
    _hireDateCtrl = TextEditingController(
      text: e?.joinDate ?? DateTime.now().toString().substring(0, 10),
    );
    _probationEndCtrl = TextEditingController(text: '');
    _terminationDateCtrl = TextEditingController(
      text: e?.terminationDate ?? '',
    );
    _employmentType = e?.employmentType ?? 'full_time';
    _employmentStatus = e?.employmentStatus ?? 'active';
    _role = e?.role ?? 'employee';
    _departmentId = e?.departmentId;
    _positionId = e?.positionId;
    _branchId = e?.branchId;
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    // Payroll
    _salaryCtrl = TextEditingController(text: e?.salary?.toString() ?? '');
    _bankNameCtrl = TextEditingController(text: e?.bankName ?? '');
    _bankAccountCtrl = TextEditingController(text: e?.bankAccount ?? '');

    // Emergency
    final ec = e?.emergencyContact;
    _emergNameCtrl = TextEditingController(text: ec?['name'] as String? ?? '');
    _emergRelCtrl = TextEditingController(
      text: ec?['relationship'] as String? ?? '',
    );
    _emergPhoneCtrl = TextEditingController(
      text: ec?['phone'] as String? ?? '',
    );

    _passwordCtrl = TextEditingController();
    _createAccount = e == null;

    if (e == null) {
      _fetchNextEmployeeId();
    }
  }

  Future<void> _fetchNextEmployeeId() async {
    try {
      final repo = ref.read(hrRepositoryProvider);
      final nextId = await repo.getNextEmployeeId();
      if (mounted) {
        setState(() {
          _employeeIdCtrl.text = nextId;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl,
      _khmerNameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _nationalIdCtrl,
      _addressCtrl,
      _hireDateCtrl,
      _probationEndCtrl,
      _terminationDateCtrl,
      _notesCtrl,
      _salaryCtrl,
      _bankNameCtrl,
      _bankAccountCtrl,
      _emergNameCtrl,
      _emergRelCtrl,
      _emergPhoneCtrl,
      _passwordCtrl,
      ..._phoneNumberCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => ctrl.text = picked.toString().substring(0, 10));
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (img != null) {
      final compressed = await ImageCompressor.compressToWebp(img.path);
      setState(() => _pickedPhoto = compressed);
    }
  }

  Future<void> _pickNationalIdImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(maxWidth: 800, imageQuality: 80);
    if (images.isNotEmpty) {
      final compressed = <File>[];
      for (final img in images) {
        final file = await ImageCompressor.compressToWebp(img.path);
        compressed.add(file);
      }
      setState(() => _pickedNationalIdImages.addAll(compressed));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(hrRepositoryProvider);
      final dobStr = _dateOfBirth?.toString().substring(0, 10);

      final phoneNumbers = _phoneNumberCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.employee == null) {
        await repo.createEmployee(
          fullName: _fullNameCtrl.text.trim(),
          khmerName: _khmerNameCtrl.text.trim().isEmpty
              ? null
              : _khmerNameCtrl.text.trim(),
          employeeId: _employeeIdCtrl.text.trim().isEmpty
              ? null
              : _employeeIdCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          phoneNumbers: phoneNumbers.isNotEmpty ? phoneNumbers : null,
          salary: double.tryParse(_salaryCtrl.text),
          employmentType: _employmentType!,
          employmentStatus: _employmentStatus!,
          hireDate: _hireDateCtrl.text,
          probationEndDate: _probationEndCtrl.text.isEmpty
              ? null
              : _probationEndCtrl.text,
          terminationDate: _terminationDateCtrl.text.isEmpty
              ? null
              : _terminationDateCtrl.text,
          departmentId: _departmentId,
          positionId: _positionId,
          branchId: _branchId,
          teamId: _teamId,
          managerId: _managerId,
          gender: _gender,
          dateOfBirth: dobStr,
          maritalStatus: _maritalStatus,
          nationalId: _nationalIdCtrl.text.trim().isEmpty
              ? null
              : _nationalIdCtrl.text.trim(),
          nationalIdImages: _pickedNationalIdImages.isNotEmpty
              ? _pickedNationalIdImages
              : null,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          bankName: _bankNameCtrl.text.trim().isEmpty
              ? null
              : _bankNameCtrl.text.trim(),
          bankAccount: _bankAccountCtrl.text.trim().isEmpty
              ? null
              : _bankAccountCtrl.text.trim(),
          emergencyContactName: _emergNameCtrl.text.trim().isEmpty
              ? null
              : _emergNameCtrl.text.trim(),
          emergencyContactRelationship: _emergRelCtrl.text.trim().isEmpty
              ? null
              : _emergRelCtrl.text.trim(),
          emergencyContactPhone: _emergPhoneCtrl.text.trim().isEmpty
              ? null
              : _emergPhoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          role: _role,
          photo: _pickedPhoto,
          createAccount: _createAccount,
          password: _createAccount && _passwordCtrl.text.isNotEmpty
              ? _passwordCtrl.text
              : null,
        );
      } else {
        await repo.updateEmployee(
          widget.employee!.id,
          fullName: _fullNameCtrl.text.trim(),
          khmerName: _khmerNameCtrl.text.trim().isEmpty
              ? null
              : _khmerNameCtrl.text.trim(),
          employeeId: _employeeIdCtrl.text.trim().isEmpty
              ? null
              : _employeeIdCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          phoneNumbers: phoneNumbers,
          salary: double.tryParse(_salaryCtrl.text),
          employmentType: _employmentType,
          employmentStatus: _employmentStatus,
          hireDate: _hireDateCtrl.text,
          probationEndDate: _probationEndCtrl.text.isEmpty
              ? null
              : _probationEndCtrl.text,
          terminationDate: _terminationDateCtrl.text.isEmpty
              ? null
              : _terminationDateCtrl.text,
          departmentId: _departmentId,
          positionId: _positionId,
          branchId: _branchId,
          teamId: _teamId,
          managerId: _managerId,
          gender: _gender,
          dateOfBirth: dobStr,
          maritalStatus: _maritalStatus,
          nationalId: _nationalIdCtrl.text.trim().isEmpty
              ? null
              : _nationalIdCtrl.text.trim(),
          nationalIdImages: _pickedNationalIdImages.isNotEmpty
              ? _pickedNationalIdImages
              : null,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          bankName: _bankNameCtrl.text.trim().isEmpty
              ? null
              : _bankNameCtrl.text.trim(),
          bankAccount: _bankAccountCtrl.text.trim().isEmpty
              ? null
              : _bankAccountCtrl.text.trim(),
          emergencyContactName: _emergNameCtrl.text.trim().isEmpty
              ? null
              : _emergNameCtrl.text.trim(),
          emergencyContactRelationship: _emergRelCtrl.text.trim().isEmpty
              ? null
              : _emergRelCtrl.text.trim(),
          emergencyContactPhone: _emergPhoneCtrl.text.trim().isEmpty
              ? null
              : _emergPhoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          role: _role,
          photo: _pickedPhoto,
          createAccount: _createAccount,
          password: _createAccount && _passwordCtrl.text.isNotEmpty
              ? _passwordCtrl.text
              : null,
        );
      }

      ref.invalidate(allEmployeesProvider);
      ref.invalidate(adminEmployeesProvider);
      ref.invalidate(dashboardStatsProvider);
      if (widget.employee != null) {
        ref.invalidate(employeeDetailProvider(widget.employee!.id));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.textPrimary(context),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.employee == null
                      ? AppLocalizations.of(context)!.employeeCreatedSuccess
                      : AppLocalizations.of(context)!.employeeUpdatedSuccess,
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$e', maxLines: 2)),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
        title: Text(
          isEditing ? l10n.editEmployee : l10n.addEmployee,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withAlpha(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo Banner ──────────────────────────────────────
              _buildPhotoBanner(isEditing, l10n),

              // ── Personal Info ─────────────────────────────────────
              _Section(
                title: l10n.personalInformation,
                icon: Icons.person_outline_rounded,
                children: [
                  _buildRow([
                    _buildField(
                      controller: _fullNameCtrl,
                      label: l10n.fullName,
                      required: true,
                      icon: Icons.badge_outlined,
                      l10n: l10n,
                    ),
                    _buildField(
                      controller: _khmerNameCtrl,
                      label: l10n.khmerName,
                      l10n: l10n,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _employeeIdCtrl,
                    label: l10n.employeeIdHint,
                    icon: Icons.badge_outlined,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _emailCtrl,
                    label: (!isEditing && _createAccount)
                        ? l10n.emailAddressRequired
                        : l10n.emailAddress,
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    required: !isEditing && _createAccount,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _phoneCtrl,
                    label: l10n.phoneNumber,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    l10n: l10n,
                  ),
                  // ── Additional Phone Numbers ───────────────────────
                  if (_phoneNumberCtrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._phoneNumberCtrls.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ctrl = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: ctrl,
                                label: l10n.phoneNumber,
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                                l10n: l10n,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                ctrl.dispose();
                                _phoneNumberCtrls.removeAt(i);
                              }),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _phoneNumberCtrls.add(TextEditingController());
                    }),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.addPhoneNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDropdown<String>(
                      label: l10n.gender,
                      value: _gender,
                      items: {
                        'male': l10n.male,
                        'female': l10n.female,
                        'other': l10n.other,
                      },
                      onChanged: (v) => setState(() => _gender = v),
                      l10n: l10n,
                    ),
                    _buildDropdown<String>(
                      label: l10n.maritalStatus,
                      value: _maritalStatus,
                      items: {
                        'single': l10n.single,
                        'married': l10n.married,
                        'divorced': l10n.divorced,
                        'widowed': l10n.widowed,
                      },
                      onChanged: (v) => setState(() => _maritalStatus = v),
                      l10n: l10n,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Date of Birth
                  InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecor(
                        l10n.dateOfBirth,
                        icon: Icons.cake_outlined,
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? _dateOfBirth.toString().substring(0, 10)
                            : l10n.tapToSelect,
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateOfBirth != null
                              ? AppColors.grey800
                              : AppColors.grey400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _nationalIdCtrl,
                    label: l10n.nationalIdPassport,
                    icon: Icons.credit_card_outlined,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  // ── National ID Images ──────────────────────────────
                  if (_pickedNationalIdImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _pickedNationalIdImages.asMap().entries.map((
                        entry,
                      ) {
                        final i = entry.key;
                        final file = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                file,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _pickedNationalIdImages.removeAt(i),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickNationalIdImages,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.grey300,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_outlined,
                            size: 16,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.uploadIdImages,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _addressCtrl,
                    label: l10n.address,
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    l10n: l10n,
                  ),
                ],
              ),

              // ── Employment Details ─────────────────────────────────
              _Section(
                title: l10n.employmentDetailsRequired,
                icon: Icons.work_outline_rounded,
                children: [
                  _buildRow([
                    _buildDropdown<String>(
                      label: l10n.employmentTypeRequired,
                      value: _employmentType,
                      required: true,
                      items: {
                        'full_time': l10n.fullTime,
                        'part_time': l10n.partTime,
                        'contract': l10n.contract,
                        'intern': l10n.intern,
                      },
                      onChanged: (v) => setState(() => _employmentType = v),
                      l10n: l10n,
                    ),
                    _buildDropdown<String>(
                      label: l10n.statusRequired,
                      value: _employmentStatus,
                      required: true,
                      items: {
                        'active': l10n.active,
                        'inactive': l10n.inactive,
                        'terminated': l10n.terminated,
                        'resigned': l10n.resigned,
                        'on_leave': l10n.onLeave,
                      },
                      onChanged: (v) => setState(() => _employmentStatus = v),
                      l10n: l10n,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDateField(
                      label: l10n.hireDateRequired,
                      ctrl: _hireDateCtrl,
                      required: true,
                      l10n: l10n,
                    ),
                    _buildDateField(
                      label: l10n.probationEnd,
                      ctrl: _probationEndCtrl,
                      l10n: l10n,
                    ),
                  ]),
                  if (_employmentStatus == 'terminated' ||
                      _employmentStatus == 'resigned') ...[
                    const SizedBox(height: 12),
                    _buildDateField(
                      label: l10n.terminationDate,
                      ctrl: _terminationDateCtrl,
                      l10n: l10n,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDropdown<String>(
                    label: l10n.systemRoleRequired,
                    value: _role,
                    required: true,
                    items: {
                      'employee': l10n.roleEmployee,
                      'branch_manager': l10n.roleBranchManager,
                      'company_admin': l10n.roleCompanyAdmin,
                      'company_owner': l10n.roleCompanyOwner,
                    },
                    onChanged: (v) => setState(() => _role = v),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDepartmentDropdown(l10n),
                    _buildPositionDropdown(l10n),
                  ]),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildBranchDropdown(l10n),
                    _buildTeamDropdown(l10n),
                  ]),
                  const SizedBox(height: 12),
                  _buildManagerDropdown(l10n),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _notesCtrl,
                    label: l10n.adminNotes,
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    l10n: l10n,
                  ),
                ],
              ),

              // ── Payroll ────────────────────────────────────────────
              _Section(
                title: l10n.payrollAndBank,
                icon: Icons.account_balance_outlined,
                children: [
                  _buildField(
                    controller: _salaryCtrl,
                    label: l10n.monthlySalary,
                    icon: Icons.attach_money_outlined,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _bankNameCtrl,
                    label: l10n.bankName,
                    icon: Icons.account_balance_outlined,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _bankAccountCtrl,
                    label: l10n.bankAccountNumber,
                    icon: Icons.credit_card_outlined,
                    l10n: l10n,
                  ),
                ],
              ),

              // ── Emergency Contact ──────────────────────────────────
              _Section(
                title: l10n.emergencyContact,
                icon: Icons.emergency_outlined,
                children: [
                  _buildField(
                    controller: _emergNameCtrl,
                    label: l10n.contactName,
                    icon: Icons.person_outline_rounded,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildField(
                      controller: _emergRelCtrl,
                      label: l10n.relationship,
                      icon: Icons.people_outline_rounded,
                      l10n: l10n,
                    ),
                    _buildField(
                      controller: _emergPhoneCtrl,
                      label: l10n.phoneNumber,
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      l10n: l10n,
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 20),

              _Section(
                title: l10n.systemAccess,
                icon: Icons.computer_outlined,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _createAccount,
                        onChanged: (v) =>
                            setState(() => _createAccount = v ?? true),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          isEditing
                              ? l10n.resetPasswordHint
                              : l10n.createAccountHint,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_createAccount) ...[
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _passwordCtrl,
                      label: l10n.passwordRequired,
                      icon: Icons.lock_outline,
                      required: true,
                      obscureText: !_showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      l10n: l10n,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.passwordLoginHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),

              // ── Save Button ────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _isLoading
                      ? l10n.saving
                      : (isEditing ? l10n.updateEmployee : l10n.createEmployee),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Photo Banner ──────────────────────────────────────────────────────────
  Widget _buildPhotoBanner(bool isEditing, AppLocalizations l10n) {
    final emp = widget.employee;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withAlpha(50),
                  backgroundImage: _pickedPhoto != null
                      ? FileImage(_pickedPhoto!) as ImageProvider
                      : (emp?.avatar != null
                            ? NetworkImage(
                                emp!.avatar!.startsWith('http')
                                    ? emp.avatar!
                                    : '${DioClient.storageUrl}/${emp.avatar!.startsWith('/') ? emp.avatar!.substring(1) : emp.avatar!}',
                              )
                            : null),
                  child: (_pickedPhoto == null && (emp?.avatar == null))
                      ? Text(
                          emp != null
                              ? (emp.firstName?.isNotEmpty == true
                                    ? emp.firstName![0].toUpperCase()
                                    : 'E')
                              : 'E',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? '${widget.employee!.firstName ?? ''} ${widget.employee!.lastName ?? ''}'
                      : l10n.newEmployee,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tapPhotoToChange,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Builder Helpers ───────────────────────────────────────────────────────

  Widget _buildRow(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.expand((w) => [w, const SizedBox(height: 12)]).toList()
        ..removeLast(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    AppLocalizations? l10n,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: _fieldDecor(label, icon: icon, suffixIcon: suffixIcon),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? (l10n?.required ?? 'Required')
                : null
          : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController ctrl,
    bool required = false,
    AppLocalizations? l10n,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: const TextStyle(fontSize: 14),
      decoration: _fieldDecor(label, icon: Icons.calendar_today_outlined),
      onTap: () => _pickDate(ctrl),
      validator: required
          ? (v) =>
                (v == null || v.isEmpty) ? (l10n?.required ?? 'Required') : null
          : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required void Function(T?) onChanged,
    bool required = false,
    AppLocalizations? l10n,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _fieldDecor(label),
      style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(
            l10n?.none ?? '— None —',
            style: TextStyle(color: AppColors.grey400),
          ),
        ),
        ...items.entries.map(
          (e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: onChanged,
      validator: required
          ? (v) => v == null ? (l10n?.required ?? 'Required') : null
          : null,
    );
  }

  Widget _buildDepartmentDropdown(AppLocalizations l10n) {
    final async = ref.watch(departmentsProvider);
    return async.when(
      data: (depts) => DropdownButtonFormField<int>(
        initialValue: _departmentId,
        decoration: _fieldDecor('Department', icon: Icons.business_outlined),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text(l10n.none, style: TextStyle(color: AppColors.grey400)),
          ),
          ...depts.map(
            (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
          ),
        ],
        onChanged: (v) => setState(() => _departmentId = v),
      ),
      loading: () => _fieldLoading('Department'),
      error: (_, _) => _fieldError('Department'),
    );
  }

  Widget _buildPositionDropdown(AppLocalizations l10n) {
    final async = ref.watch(positionsProvider);
    return async.when(
      data: (pos) => DropdownButtonFormField<int>(
        initialValue: _positionId,
        decoration: _fieldDecor('Position', icon: Icons.work_outline),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text(l10n.none, style: TextStyle(color: AppColors.grey400)),
          ),
          ...pos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
        ],
        onChanged: (v) => setState(() => _positionId = v),
      ),
      loading: () => _fieldLoading('Position'),
      error: (_, _) => _fieldError('Position'),
    );
  }

  Widget _buildBranchDropdown(AppLocalizations l10n) {
    final async = ref.watch(branchesProvider);
    return async.when(
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: _branchId,
        decoration: _fieldDecor('Branch', icon: Icons.location_city_outlined),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text(l10n.none, style: TextStyle(color: AppColors.grey400)),
          ),
          ...branches.map(
            (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
          ),
        ],
        onChanged: (v) => setState(() => _branchId = v),
      ),
      loading: () => _fieldLoading('Branch'),
      error: (_, _) => _fieldError('Branch'),
    );
  }

  Widget _buildTeamDropdown(AppLocalizations l10n) {
    final async = ref.watch(teamsProvider);
    return async.when(
      data: (teams) => DropdownButtonFormField<int>(
        initialValue: _teamId,
        decoration: _fieldDecor('Team', icon: Icons.group_outlined),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text(l10n.none, style: TextStyle(color: AppColors.grey400)),
          ),
          ...teams.map(
            (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
          ),
        ],
        onChanged: (v) => setState(() => _teamId = v),
      ),
      loading: () => _fieldLoading('Team'),
      error: (_, _) => _fieldError('Team'),
    );
  }

  Widget _buildManagerDropdown(AppLocalizations l10n) {
    final async = ref.watch(allEmployeesProvider);
    return async.when(
      data: (employees) => DropdownButtonFormField<int>(
        initialValue: _managerId,
        decoration: _fieldDecor(
          'Direct Manager',
          icon: Icons.manage_accounts_outlined,
        ),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text(l10n.none, style: TextStyle(color: AppColors.grey400)),
          ),
          ...employees
              .where((e) => e.id != widget.employee?.id)
              .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
        ],
        onChanged: (v) => setState(() => _managerId = v),
      ),
      loading: () => _fieldLoading('Manager'),
      error: (_, _) => _fieldError('Manager'),
    );
  }

  Widget _fieldLoading(String label) => InputDecorator(
    decoration: _fieldDecor(label),
    child: const LinearProgressIndicator(),
  );

  Widget _fieldError(String label) => InputDecorator(
    decoration: _fieldDecor(label),
    child: Text(
      'Error loading',
      style: TextStyle(color: AppColors.danger, fontSize: 13),
    ),
  );
}
