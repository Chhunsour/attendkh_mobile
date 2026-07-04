import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mpg_hr_mobile_app/core/theme/theme.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/data/hr_repository.dart';
import 'package:mpg_hr_mobile_app/features/company_admin/presentation/admin_providers.dart';

class AdminEmployeeFormScreen extends ConsumerStatefulWidget {
  final EmployeeData? employee;
  const AdminEmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<AdminEmployeeFormScreen> createState() => _AdminEmployeeFormScreenState();
}

class _AdminEmployeeFormScreenState extends ConsumerState<AdminEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _salaryCtrl;
  late TextEditingController _hireDateCtrl;

  String? _employmentType;
  String? _employmentStatus;
  int? _departmentId;
  int? _positionId;
  int? _branchId;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _firstNameCtrl = TextEditingController(text: e?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: e?.lastName ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _salaryCtrl = TextEditingController(text: e?.salary?.toString() ?? '');
    _hireDateCtrl = TextEditingController(text: e?.joinDate ?? DateTime.now().toString().substring(0, 10));

    _employmentType = e?.employmentType ?? 'full_time';
    _employmentStatus = e?.employmentStatus ?? 'active';
    _departmentId = e?.departmentId;
    _positionId = e?.positionId;
    _branchId = e?.branchId;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    _hireDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _hireDateCtrl.text = date.toString().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(hrRepositoryProvider);
      if (widget.employee == null) {
        await repo.createEmployee(
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          salary: double.tryParse(_salaryCtrl.text),
          employmentType: _employmentType!,
          employmentStatus: _employmentStatus!,
          hireDate: _hireDateCtrl.text,
          departmentId: _departmentId,
          positionId: _positionId,
          branchId: _branchId,
        );
      } else {
        await repo.updateEmployee(
          widget.employee!.id,
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          salary: double.tryParse(_salaryCtrl.text),
          employmentType: _employmentType!,
          employmentStatus: _employmentStatus!,
          hireDate: _hireDateCtrl.text,
          departmentId: _departmentId,
          positionId: _positionId,
          branchId: _branchId,
        );
      }
      ref.invalidate(employeesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Employee saved successfully'), backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.employee == null ? 'Add Employee' : 'Edit Employee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _salaryCtrl, decoration: const InputDecoration(labelText: 'Base Salary', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hireDateCtrl,
                      decoration: const InputDecoration(labelText: 'Hire Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: _pickDate,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Employment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _employmentType,
                decoration: const InputDecoration(labelText: 'Employment Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'full_time', child: Text('Full Time')),
                  DropdownMenuItem(value: 'part_time', child: Text('Part Time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'intern', child: Text('Intern')),
                ],
                onChanged: (v) => setState(() => _employmentType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _employmentStatus,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'terminated', child: Text('Terminated')),
                  DropdownMenuItem(value: 'resigned', child: Text('Resigned')),
                  DropdownMenuItem(value: 'on_leave', child: Text('On Leave')),
                ],
                onChanged: (v) => setState(() => _employmentStatus = v),
              ),
              const SizedBox(height: 12),
              _buildDepartmentDropdown(),
              const SizedBox(height: 12),
              _buildPositionDropdown(),
              const SizedBox(height: 12),
              _buildBranchDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    final deptsAsync = ref.watch(departmentsProvider);
    return deptsAsync.when(
      data: (depts) => DropdownButtonFormField<int>(
        initialValue: _departmentId,
        decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('None')),
          ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
        ],
        onChanged: (v) => setState(() => _departmentId = v),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('Error loading departments'),
    );
  }

  Widget _buildPositionDropdown() {
    final posAsync = ref.watch(positionsProvider);
    return posAsync.when(
      data: (pos) => DropdownButtonFormField<int>(
        initialValue: _positionId,
        decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('None')),
          ...pos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
        ],
        onChanged: (v) => setState(() => _positionId = v),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('Error loading positions'),
    );
  }

  Widget _buildBranchDropdown() {
    final branchesAsync = ref.watch(branchesProvider);
    return branchesAsync.when(
      data: (branches) => DropdownButtonFormField<int>(
        initialValue: _branchId,
        decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('None')),
          ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
        ],
        onChanged: (v) => setState(() => _branchId = v),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const Text('Error loading branches'),
    );
  }
}
