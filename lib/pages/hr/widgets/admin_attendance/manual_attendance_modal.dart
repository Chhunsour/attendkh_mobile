import 'package:attendkh/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/hr_repository.dart';
import 'package:attendkh/services/network/dio_client.dart';
import 'package:attendkh/utils/theme/theme.dart';

class ManualAttendanceModal extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const ManualAttendanceModal({super.key, required this.onSaved});

  @override
  ConsumerState<ManualAttendanceModal> createState() =>
      _ManualAttendanceModalState();
}

class _ManualAttendanceModalState extends ConsumerState<ManualAttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  EmployeeData? _selectedEmployee;
  final _dateController = TextEditingController(
    text: DateTime.now().toIso8601String().split('T')[0],
  );
  final _clockInController = TextEditingController();
  final _clockOutController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'present';
  bool _isSaving = false;

  @override
  void dispose() {
    _dateController.dispose();
    _clockInController.dispose();
    _clockOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(EmployeeData emp, {double size = 40, bool isSelected = false}) {
    final displayName = emp.fullName ?? emp.name;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (emp.avatar != null && emp.avatar!.isNotEmpty) {
      final imgUrl = emp.avatar!.startsWith('http')
          ? emp.avatar!
          : '${DioClient.storageUrl}/${emp.avatar!.startsWith('/') ? emp.avatar!.substring(1) : emp.avatar!}';
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            width: size,
            height: size,
            color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFE0E7FF),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (_, _, _) =>
              _buildFallbackAvatar(displayName, size, isSelected, isDark),
        ),
      );
    }
    return _buildFallbackAvatar(displayName, size, isSelected, isDark);
  }

  Widget _buildFallbackAvatar(
    String name,
    double size,
    bool isSelected,
    bool isDark,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF10B981)
            : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFE0E7FF)),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'E',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
            color: isSelected ? Colors.white : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  void _openEmployeePicker(List<EmployeeData> employees) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filtered = employees.where((e) {
              final q = query.toLowerCase();
              final name = (e.fullName ?? e.name).toLowerCase();
              final code = (e.employeeId ?? '').toLowerCase();
              final dept = (e.department ?? '').toLowerCase();
              return name.contains(q) || code.contains(q) || dept.contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.selectEmployee ?? 'Select Employee',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      autofocus: false,
                      onChanged: (val) =>
                          setPickerState(() => query = val.trim()),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)?.searchEmployeeHint ?? 'Search by name, ID or department...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDarkElevated
                            : AppColors.grey50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context)?.noMatchingEmployeesFound ?? 'No employees found',
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 64),
                            itemBuilder: (context, i) {
                              final emp = filtered[i];
                              final isSelected =
                                  _selectedEmployee?.id == emp.id;
                              final displayName = emp.fullName ?? emp.name;
                              return ListTile(
                                onTap: () {
                                  setState(() => _selectedEmployee = emp);
                                  Navigator.pop(ctx);
                                },
                                leading: _buildAvatar(
                                  emp,
                                  size: 40,
                                  isSelected: isSelected,
                                ),
                                title: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                subtitle: Text(
                                  '${emp.employeeId ?? '#${emp.id}'}${emp.department != null && emp.department!.isNotEmpty ? ' • ${emp.department}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF10B981),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee first.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminOpsRepositoryProvider);
      await repo.addManualAttendance({
        'employee_id': _selectedEmployee!.id.toString(),
        'date': _dateController.text.trim(),
        'clock_in': _clockInController.text.trim().isEmpty
            ? null
            : _clockInController.text.trim(),
        'clock_out': _clockOutController.text.trim().isEmpty
            ? null
            : _clockOutController.text.trim(),
        'status': _status,
        'notes': _notesController.text.trim(),
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual attendance record added.'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employeesAsync = ref.watch(allEmployeesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom +
            20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.manualAttendanceEntry,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.grey500,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Employee Selector
              employeesAsync.when(
                data: (employees) => InkWell(
                  onTap: () => _openEmployeePicker(employees),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkElevated
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedEmployee != null
                            ? const Color(0xFF10B981)
                            : AppColors.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_selectedEmployee != null)
                          _buildAvatar(_selectedEmployee!, size: 36)
                        else
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 24,
                            color: AppColors.grey400,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedEmployee != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedEmployee!.fullName ??
                                          _selectedEmployee!.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    Text(
                                      '${_selectedEmployee!.employeeId ?? '#${_selectedEmployee!.id}'}${_selectedEmployee!.department != null ? ' • ${_selectedEmployee!.department}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.grey500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  l10n.selectEmployeeRequired,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.grey400
                                        : AppColors.grey500,
                                  ),
                                ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading employees...',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                error: (e, _) => Text(
                  l10n.failedToLoadEmployees,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dateController,
                decoration: _inputDecoration(
                  l10n.date,
                  Icons.calendar_today_outlined,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter date' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clockInController,
                      decoration: _inputDecoration(
                        l10n.clockInTime,
                        Icons.login_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _clockOutController,
                      decoration: _inputDecoration(
                        l10n.clockOutTime,
                        Icons.logout_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _inputDecoration(
                  l10n.status,
                  Icons.check_circle_outline_rounded,
                ),
                items: [
                  DropdownMenuItem(value: 'present', child: Text(l10n.present)),
                  DropdownMenuItem(value: 'late', child: Text(l10n.late)),
                  DropdownMenuItem(value: 'absent', child: Text(l10n.absent)),
                  DropdownMenuItem(value: 'on_leave', child: Text(l10n.onLeave)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(
                  l10n.reason,
                  Icons.edit_note_rounded,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.grey500),
      prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF10B981)),
      ),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDarkElevated
          : AppColors.grey50,
    );
  }
}
