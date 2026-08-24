import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/assets_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_assets/asset_shared_widgets.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_assets/employee_picker_sheet.dart';

class AssetAssignSheet extends StatefulWidget {
  final AssetData asset;
  final VoidCallback onAssigned;

  const AssetAssignSheet({
    super.key,
    required this.asset,
    required this.onAssigned,
  });

  static void show({
    required BuildContext context,
    required AssetData asset,
    required VoidCallback onAssigned,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetAssignSheet(
        asset: asset,
        onAssigned: onAssigned,
      ),
    );
  }

  @override
  State<AssetAssignSheet> createState() => _AssetAssignSheetState();
}

class _AssetAssignSheetState extends State<AssetAssignSheet> {
  final _conditionCtrl = TextEditingController();
  Map<String, dynamic>? _selectedEmployee;
  List<Map<String, dynamic>> _employees = [];
  bool _isFetching = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    try {
      final data = await AdminOperationsRepository().getEmployees();
      if (mounted) {
        setState(() {
          _employees = data;
          _isFetching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _employees = [];
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectEmployee),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final employeeId = _selectedEmployee!['id'] as int;
      await AssetsRepository().assignAsset(
        widget.asset.id,
        employeeId,
        conditionAtAssignment: _conditionCtrl.text.trim().isNotEmpty
            ? _conditionCtrl.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.assetAssignedSuccess}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onAssigned();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.assignAssetTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.transferAssetDesc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
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
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Asset info preview card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(20),
                              AppColors.primary.withAlpha(5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                AssetSharedWidgets.categoryIcon(
                                  widget.asset.category,
                                ),
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.asset.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.asset.assetCode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Employee Selector Header
                      Text(
                        l10n.assignToEmployeeRequired,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Employee Selector Card / Button
                      if (_isFetching)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (_selectedEmployee == null)
                        GestureDetector(
                          onTap: () => EmployeePickerSheet.show(
                            context: context,
                            employees: _employees,
                            currentSelected: _selectedEmployee,
                            onSelected: (emp) =>
                                setState(() => _selectedEmployee = emp),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_add_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.selectEmployee,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Tap to search & choose employee',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.grey500,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(40),
                            ),
                          ),
                          child: Row(
                            children: [
                              AssetSharedWidgets.buildEmployeeAvatar(
                                photoUrl:
                                    _selectedEmployee!['photo_url']
                                        as String? ??
                                    _selectedEmployee!['avatar'] as String?,
                                name:
                                    (_selectedEmployee!['full_name']
                                                as String? ??
                                            _selectedEmployee!['name']
                                                as String? ??
                                            '${_selectedEmployee!['first_name'] ?? ''} ${_selectedEmployee!['last_name'] ?? ''}')
                                        .trim(),
                                size: 44,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            (_selectedEmployee!['full_name']
                                                        as String? ??
                                                    _selectedEmployee!['name']
                                                        as String? ??
                                                    '${_selectedEmployee!['first_name'] ?? ''} ${_selectedEmployee!['last_name'] ?? ''}')
                                                .trim(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary(
                                                context,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_selectedEmployee!['employee_id'] !=
                                            null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _selectedEmployee!['employee_id']
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (_selectedEmployee!['khmer_name'] !=
                                        null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedEmployee!['khmer_name']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    ],
                                    if (_selectedEmployee!['position'] !=
                                        null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedEmployee!['position'] is Map
                                            ? (_selectedEmployee!['position']['name']
                                                    as String? ??
                                                '')
                                            : _selectedEmployee!['position']
                                                .toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => EmployeePickerSheet.show(
                                  context: context,
                                  employees: _employees,
                                  currentSelected: _selectedEmployee,
                                  onSelected: (emp) =>
                                      setState(() => _selectedEmployee = emp),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _conditionCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.conditionAtAssignmentLabel,
                          hintText: l10n.conditionNoteHint,
                          labelStyle: const TextStyle(
                            color: AppColors.grey600,
                          ),
                          hintStyle: const TextStyle(
                            color: AppColors.grey400,
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppColors.primary.withAlpha(100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.confirmAssignmentBtn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
