import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/services/hr_repository.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

InputDecoration _fieldDecor(String label, {IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.grey400) : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.grey200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.grey200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
    labelStyle: TextStyle(fontSize: 14, color: AppColors.grey500),
    floatingLabelStyle: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});

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
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(title.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
  ConsumerState<AdminEmployeeFormScreen> createState() => _AdminEmployeeFormScreenState();
}

class _AdminEmployeeFormScreenState extends ConsumerState<AdminEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _pickedPhoto;

  // Personal
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _nationalIdCtrl;
  late TextEditingController _addressCtrl;
  String? _gender;
  DateTime? _dateOfBirth;
  String? _maritalStatus;

  // Employment
  late TextEditingController _hireDateCtrl;
  late TextEditingController _probationEndCtrl;
  late TextEditingController _terminationDateCtrl;
  String? _employmentType;
  String? _employmentStatus;
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

  @override
  void initState() {
    super.initState();
    final e = widget.employee;

    // Personal
    _firstNameCtrl  = TextEditingController(text: e?.firstName ?? '');
    _lastNameCtrl   = TextEditingController(text: e?.lastName ?? '');
    _emailCtrl      = TextEditingController(text: e?.email ?? '');
    _phoneCtrl      = TextEditingController(text: e?.phone ?? '');
    _nationalIdCtrl = TextEditingController(text: e?.nationalId ?? '');
    _addressCtrl    = TextEditingController(text: e?.address ?? '');
    _gender         = e?.gender;
    _maritalStatus  = e?.maritalStatus;
    if (e?.dateOfBirth != null) {
      _dateOfBirth = DateTime.tryParse(e!.dateOfBirth!);
    }

    // Employment
    _hireDateCtrl   = TextEditingController(text: e?.joinDate ?? DateTime.now().toString().substring(0, 10));
    _probationEndCtrl = TextEditingController(text: '');
    _terminationDateCtrl = TextEditingController(text: e?.terminationDate ?? '');
    _employmentType   = e?.employmentType ?? 'full_time';
    _employmentStatus = e?.employmentStatus ?? 'active';
    _departmentId     = e?.departmentId;
    _positionId       = e?.positionId;
    _branchId         = e?.branchId;
    _notesCtrl        = TextEditingController(text: e?.notes ?? '');

    // Payroll
    _salaryCtrl      = TextEditingController(text: e?.salary?.toString() ?? '');
    _bankNameCtrl    = TextEditingController(text: e?.bankName ?? '');
    _bankAccountCtrl = TextEditingController(text: e?.bankAccount ?? '');

    // Emergency
    final ec         = e?.emergencyContact;
    _emergNameCtrl   = TextEditingController(text: ec?['name'] as String? ?? '');
    _emergRelCtrl    = TextEditingController(text: ec?['relationship'] as String? ?? '');
    _emergPhoneCtrl  = TextEditingController(text: ec?['phone'] as String? ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl, _nationalIdCtrl,
      _addressCtrl, _hireDateCtrl, _probationEndCtrl, _terminationDateCtrl, _notesCtrl,
      _salaryCtrl, _bankNameCtrl, _bankAccountCtrl,
      _emergNameCtrl, _emergRelCtrl, _emergPhoneCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => ctrl.text = picked.toString().substring(0, 10));
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (img != null) setState(() => _pickedPhoto = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(hrRepositoryProvider);
      final dobStr = _dateOfBirth?.toString().substring(0, 10);

      if (widget.employee == null) {
        await repo.createEmployee(
          firstName: _firstNameCtrl.text.trim(),
          lastName:  _lastNameCtrl.text.trim(),
          email:     _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          salary:    double.tryParse(_salaryCtrl.text),
          employmentType:   _employmentType!,
          employmentStatus: _employmentStatus!,
          hireDate:   _hireDateCtrl.text,
          probationEndDate: _probationEndCtrl.text.isEmpty ? null : _probationEndCtrl.text,
          terminationDate: _terminationDateCtrl.text.isEmpty ? null : _terminationDateCtrl.text,
          departmentId: _departmentId,
          positionId:   _positionId,
          branchId:     _branchId,
          teamId:       _teamId,
          managerId:    _managerId,
          gender:       _gender,
          dateOfBirth:  dobStr,
          maritalStatus: _maritalStatus,
          nationalId:   _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
          address:      _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          bankName:     _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
          bankAccount:  _bankAccountCtrl.text.trim().isEmpty ? null : _bankAccountCtrl.text.trim(),
          emergencyContactName:         _emergNameCtrl.text.trim().isEmpty ? null : _emergNameCtrl.text.trim(),
          emergencyContactRelationship: _emergRelCtrl.text.trim().isEmpty ? null : _emergRelCtrl.text.trim(),
          emergencyContactPhone:        _emergPhoneCtrl.text.trim().isEmpty ? null : _emergPhoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          photo: _pickedPhoto,
        );
      } else {
        await repo.updateEmployee(
          widget.employee!.id,
          firstName: _firstNameCtrl.text.trim(),
          lastName:  _lastNameCtrl.text.trim(),
          email:     _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          salary:    double.tryParse(_salaryCtrl.text),
          employmentType:   _employmentType,
          employmentStatus: _employmentStatus,
          hireDate:   _hireDateCtrl.text,
          probationEndDate: _probationEndCtrl.text.isEmpty ? null : _probationEndCtrl.text,
          terminationDate: _terminationDateCtrl.text.isEmpty ? null : _terminationDateCtrl.text,
          departmentId: _departmentId,
          positionId:   _positionId,
          branchId:     _branchId,
          teamId:       _teamId,
          managerId:    _managerId,
          gender:       _gender,
          dateOfBirth:  dobStr,
          maritalStatus: _maritalStatus,
          nationalId:   _nationalIdCtrl.text.trim().isEmpty ? null : _nationalIdCtrl.text.trim(),
          address:      _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          bankName:     _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
          bankAccount:  _bankAccountCtrl.text.trim().isEmpty ? null : _bankAccountCtrl.text.trim(),
          emergencyContactName:         _emergNameCtrl.text.trim().isEmpty ? null : _emergNameCtrl.text.trim(),
          emergencyContactRelationship: _emergRelCtrl.text.trim().isEmpty ? null : _emergRelCtrl.text.trim(),
          emergencyContactPhone:        _emergPhoneCtrl.text.trim().isEmpty ? null : _emergPhoneCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          photo: _pickedPhoto,
        );
      }

      ref.invalidate(allEmployeesProvider);
      ref.invalidate(adminEmployeesProvider);
      if (widget.employee != null) {
        ref.invalidate(employeeDetailProvider(widget.employee!.id));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(widget.employee == null ? 'Employee created successfully' : 'Employee updated successfully'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$e', maxLines: 2)),
          ]),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          isEditing ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withAlpha(15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              _buildPhotoBanner(isEditing),

              // ── Personal Info ─────────────────────────────────────
              _Section(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildRow([
                    _buildField(
                      controller: _firstNameCtrl,
                      label: 'First Name',
                      required: true,
                      icon: Icons.badge_outlined,
                    ),
                    _buildField(
                      controller: _lastNameCtrl,
                      label: 'Last Name',
                      required: true,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildField(controller: _emailCtrl, label: 'Email Address', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildField(controller: _phoneCtrl, label: 'Phone Number', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDropdown<String>(
                      label: 'Gender',
                      value: _gender,
                      items: const {'male': 'Male', 'female': 'Female', 'other': 'Other'},
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    _buildDropdown<String>(
                      label: 'Marital Status',
                      value: _maritalStatus,
                      items: const {'single': 'Single', 'married': 'Married', 'divorced': 'Divorced', 'widowed': 'Widowed'},
                      onChanged: (v) => setState(() => _maritalStatus = v),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Date of Birth
                  InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _fieldDecor('Date of Birth', icon: Icons.cake_outlined),
                      child: Text(
                        _dateOfBirth != null ? _dateOfBirth.toString().substring(0, 10) : 'Tap to select',
                        style: TextStyle(fontSize: 14, color: _dateOfBirth != null ? Colors.black87 : AppColors.grey400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(controller: _nationalIdCtrl, label: 'National ID / Passport', icon: Icons.credit_card_outlined),
                  const SizedBox(height: 12),
                  _buildField(controller: _addressCtrl, label: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
                ],
              ),

              // ── Employment Details ─────────────────────────────────
              _Section(
                title: 'Employment Details',
                icon: Icons.work_outline_rounded,
                children: [
                  _buildRow([
                    _buildDropdown<String>(
                      label: 'Employment Type *',
                      value: _employmentType,
                      required: true,
                      items: const {'full_time': 'Full-Time', 'part_time': 'Part-Time', 'contract': 'Contract', 'intern': 'Intern'},
                      onChanged: (v) => setState(() => _employmentType = v),
                    ),
                    _buildDropdown<String>(
                      label: 'Status *',
                      value: _employmentStatus,
                      required: true,
                      items: const {'active': 'Active', 'inactive': 'Inactive', 'terminated': 'Terminated', 'resigned': 'Resigned', 'on_leave': 'On Leave'},
                      onChanged: (v) => setState(() => _employmentStatus = v),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDateField(label: 'Hire Date *', ctrl: _hireDateCtrl, required: true),
                    _buildDateField(label: 'Probation End', ctrl: _probationEndCtrl),
                  ]),
                  if (_employmentStatus == 'terminated' || _employmentStatus == 'resigned') ...[
                    const SizedBox(height: 12),
                    _buildDateField(label: 'Termination Date', ctrl: _terminationDateCtrl),
                  ],
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildDepartmentDropdown(),
                    _buildPositionDropdown(),
                  ]),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildBranchDropdown(),
                    _buildTeamDropdown(),
                  ]),
                  const SizedBox(height: 12),
                  _buildManagerDropdown(),
                  const SizedBox(height: 12),
                  _buildField(controller: _notesCtrl, label: 'Admin Notes', icon: Icons.notes_outlined, maxLines: 3),
                ],
              ),

              // ── Payroll ────────────────────────────────────────────
              _Section(
                title: 'Payroll & Bank',
                icon: Icons.account_balance_outlined,
                children: [
                  _buildField(
                    controller: _salaryCtrl,
                    label: 'Monthly Salary',
                    icon: Icons.attach_money_outlined,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  _buildField(controller: _bankNameCtrl, label: 'Bank Name', icon: Icons.account_balance_outlined),
                  const SizedBox(height: 12),
                  _buildField(controller: _bankAccountCtrl, label: 'Bank Account Number', icon: Icons.credit_card_outlined),
                ],
              ),

              // ── Emergency Contact ──────────────────────────────────
              _Section(
                title: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                children: [
                  _buildField(controller: _emergNameCtrl, label: 'Contact Name', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _buildRow([
                    _buildField(controller: _emergRelCtrl, label: 'Relationship', icon: Icons.people_outline_rounded),
                    _buildField(controller: _emergPhoneCtrl, label: 'Phone', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                  ]),
                ],
              ),

              const SizedBox(height: 20),

              // ── Save Button ────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Saving…' : (isEditing ? 'Update Employee' : 'Create Employee'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  Widget _buildPhotoBanner(bool isEditing) {
    final emp = widget.employee;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                      : (emp?.avatar != null ? NetworkImage(emp!.avatar!.startsWith('http') ? emp.avatar! : '${DioClient.storageUrl}/${emp.avatar!.startsWith('/') ? emp.avatar!.substring(1) : emp.avatar!}') : null),
                  child: (_pickedPhoto == null && (emp?.avatar == null))
                      ? Text(
                          emp != null
                              ? (emp.firstName?.isNotEmpty == true ? emp.firstName![0].toUpperCase() : 'E')
                              : 'E',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? '${widget.employee!.firstName ?? ''} ${widget.employee!.lastName ?? ''}' : 'New Employee',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Tap photo to change', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      children: children.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
    );
  }


  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: _fieldDecor(label, icon: icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildDateField({required String label, required TextEditingController ctrl, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: const TextStyle(fontSize: 14),
      decoration: _fieldDecor(label, icon: Icons.calendar_today_outlined),
      onTap: () => _pickDate(ctrl),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required void Function(T?) onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _fieldDecor(label),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      items: [
        DropdownMenuItem<T>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
        ...items.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value))),
      ],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Required' : null : null,
    );
  }

  Widget _buildDepartmentDropdown() {
    final async = ref.watch(departmentsProvider);
    return async.when(
      data: (depts) => DropdownButtonFormField<int>(
        initialValue: _departmentId,
        decoration: _fieldDecor('Department', icon: Icons.business_outlined),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
          ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
        ],
        onChanged: (v) => setState(() => _departmentId = v),
      ),
      loading: () => _fieldLoading('Department'),
      error: (_, _) => _fieldError('Department'),
    );
  }

  Widget _buildPositionDropdown() {
    final async = ref.watch(positionsProvider);
    return async.when(
      data: (pos) => DropdownButtonFormField<int>(
        initialValue: _positionId,
        decoration: _fieldDecor('Position', icon: Icons.work_outline),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
          ...pos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
        ],
        onChanged: (v) => setState(() => _positionId = v),
      ),
      loading: () => _fieldLoading('Position'),
      error: (_, _) => _fieldError('Position'),
    );
  }

  Widget _buildBranchDropdown() {
    final async = ref.watch(branchesProvider);
    return async.when(
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: _branchId,
        decoration: _fieldDecor('Branch', icon: Icons.location_city_outlined),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
          ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
        ],
        onChanged: (v) => setState(() => _branchId = v),
      ),
      loading: () => _fieldLoading('Branch'),
      error: (_, _) => _fieldError('Branch'),
    );
  }

  Widget _buildTeamDropdown() {
    final async = ref.watch(teamsProvider);
    return async.when(
      data: (teams) => DropdownButtonFormField<int>(
        initialValue: _teamId,
        decoration: _fieldDecor('Team', icon: Icons.group_outlined),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
          ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
        ],
        onChanged: (v) => setState(() => _teamId = v),
      ),
      loading: () => _fieldLoading('Team'),
      error: (_, _) => _fieldError('Team'),
    );
  }

  Widget _buildManagerDropdown() {
    final async = ref.watch(allEmployeesProvider);
    return async.when(
      data: (employees) => DropdownButtonFormField<int>(
        initialValue: _managerId,
        decoration: _fieldDecor('Direct Manager', icon: Icons.manage_accounts_outlined),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.grey400))),
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
        child: Text('Error loading', style: TextStyle(color: AppColors.danger, fontSize: 13)),
      );
}
