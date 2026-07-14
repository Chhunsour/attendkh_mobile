import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/services/assets_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';

class AdminAssetsScreen extends ConsumerStatefulWidget {
  const AdminAssetsScreen({super.key});

  @override
  ConsumerState<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends ConsumerState<AdminAssetsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers for create/edit
  final _assetCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _serialNumberCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _depreciationMonthsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _conditionAtAssignmentCtrl = TextEditingController();

  String _selectedCondition = 'new';
  String? _purchaseDate;
  String? _warrantyExpiryDate;

  // Assign modal state
  final _assignEmployeeIdCtrl = TextEditingController();
  Map<String, dynamic>? _selectedEmployee;

  @override
  void dispose() {
    _assetCodeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descriptionCtrl.dispose();
    _serialNumberCtrl.dispose();
    _modelCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _currentValueCtrl.dispose();
    _depreciationMonthsCtrl.dispose();
    _notesCtrl.dispose();
    _conditionAtAssignmentCtrl.dispose();
    _assignEmployeeIdCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _assetCodeCtrl.clear();
    _nameCtrl.clear();
    _categoryCtrl.clear();
    _descriptionCtrl.clear();
    _serialNumberCtrl.clear();
    _modelCtrl.clear();
    _purchasePriceCtrl.clear();
    _currentValueCtrl.clear();
    _depreciationMonthsCtrl.clear();
    _notesCtrl.clear();
    _conditionAtAssignmentCtrl.clear();
    _selectedCondition = 'new';
    _purchaseDate = null;
    _warrantyExpiryDate = null;
    _selectedEmployee = null;
  }

  void _populateFormFromAsset(AssetData asset) {
    _assetCodeCtrl.text = asset.assetCode;
    _nameCtrl.text = asset.name;
    _categoryCtrl.text = asset.category ?? '';
    _descriptionCtrl.text = asset.description ?? '';
    _serialNumberCtrl.text = asset.serialNumber ?? '';
    _modelCtrl.text = asset.model ?? '';
    _purchasePriceCtrl.text = asset.purchasePrice?.toString() ?? '';
    _currentValueCtrl.text = asset.currentValue?.toString() ?? '';
    _depreciationMonthsCtrl.text = asset.depreciationMonths?.toString() ?? '';
    _notesCtrl.text = asset.notes ?? '';
    _selectedCondition = asset.condition;
    _purchaseDate = asset.purchaseDate;
    _warrantyExpiryDate = asset.warrantyExpiryDate;
  }


  // ── Color helpers ──────────────────────────────────────────────────────
  Color _conditionColor(String condition) {
    switch (condition) {
      case 'new':
        return Colors.green;
      case 'good':
        return AppColors.info;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.deepOrange;
      case 'damaged':
        return AppColors.danger;
      default:
        return AppColors.grey500;
    }
  }

  Color _conditionBgColor(String condition) {
    switch (condition) {
      case 'new':
        return Colors.green.shade50;
      case 'good':
        return Colors.blue.shade50;
      case 'fair':
        return Colors.orange.shade50;
      case 'poor':
        return Colors.deepOrange.shade50;
      case 'damaged':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.success;
      case 'assigned':
        return AppColors.info;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return AppColors.grey500;
      default:
        return AppColors.grey500;
    }
  }

  IconData _categoryIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('laptop') || cat.contains('computer') || cat.contains('macbook')) return Icons.laptop;
    if (cat.contains('phone') || cat.contains('mobile')) return Icons.smartphone;
    if (cat.contains('monitor') || cat.contains('display')) return Icons.monitor;
    if (cat.contains('vehicle') || cat.contains('car') || cat.contains('truck')) return Icons.local_shipping;
    return Icons.inventory_2;
  }

  Widget _buildConditionBadge(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _conditionBgColor(condition),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _conditionColor(condition).withAlpha(77)),
      ),
      child: Text(
        condition.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _conditionColor(condition)),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────
  void _showCreateEditDialog({AssetData? asset}) {
    _resetForm();
    if (asset != null) _populateFormFromAsset(asset);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(asset != null ? 'Edit Asset' : 'Add New Asset', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                          const SizedBox(height: 4),
                          Text('Fill in the details below', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.grey500), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Info Section
                          _buildSectionHeader('Basic Details', Icons.info_outline),
                          const SizedBox(height: 16),
                          _buildModernTextField(_assetCodeCtrl, 'Asset Code *', 'e.g. AST-001'),
                          const SizedBox(height: 16),
                          _buildModernTextField(_nameCtrl, 'Name *', 'e.g. MacBook Pro M3'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildModernTextField(_categoryCtrl, 'Category', 'Laptop, Phone...')),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCondition,
                                  decoration: InputDecoration(
                                    labelText: 'Condition',
                                    labelStyle: const TextStyle(color: AppColors.grey600, fontSize: 14),
                                    filled: true,
                                    fillColor: AppColors.grey50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'new', child: Text('New')),
                                    DropdownMenuItem(value: 'good', child: Text('Good')),
                                    DropdownMenuItem(value: 'fair', child: Text('Fair')),
                                    DropdownMenuItem(value: 'poor', child: Text('Poor')),
                                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                                  ],
                                  onChanged: (v) => setSheetState(() => _selectedCondition = v ?? 'new'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildModernTextField(_modelCtrl, 'Model', 'e.g. A2991')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildModernTextField(_serialNumberCtrl, 'Serial Number', '...')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(_descriptionCtrl, 'Description', 'Detailed specs...', maxLines: 2),
                          const SizedBox(height: 24),
                          
                          // Financial Section
                          _buildSectionHeader('Financial & Depreciation', Icons.attach_money),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                                    if (date != null) setSheetState(() => _purchaseDate = date.toIso8601String().substring(0, 10));
                                  },
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Purchase Date',
                                      labelStyle: const TextStyle(color: AppColors.grey600, fontSize: 14),
                                      filled: true,
                                      fillColor: AppColors.grey50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    child: Text(_purchaseDate ?? 'Select date...', style: TextStyle(color: _purchaseDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 15)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildModernTextField(_purchasePriceCtrl, 'Purchase Price', '\$', isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildModernTextField(_currentValueCtrl, 'Current Value', '\$', isNumber: true)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildModernTextField(_depreciationMonthsCtrl, 'Depreciation', 'Months', isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Warranty & Notes Section
                          _buildSectionHeader('Warranty & Notes', Icons.verified_user_outlined),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                              if (date != null) setSheetState(() => _warrantyExpiryDate = date.toIso8601String().substring(0, 10));
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Warranty Expiry Date',
                                labelStyle: const TextStyle(color: AppColors.grey600, fontSize: 14),
                                filled: true,
                                fillColor: AppColors.grey50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: Text(_warrantyExpiryDate ?? 'Select date...', style: TextStyle(color: _warrantyExpiryDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(_notesCtrl, 'Internal Notes', 'Condition notes...', maxLines: 2),
                          const SizedBox(height: 32),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppColors.primary.withAlpha(100),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () async {
                                if (_assetCodeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset Code and Name are required'), backgroundColor: AppColors.danger));
                                  return;
                                }
                                try {
                                  final repo = AssetsRepository();
                                  final data = {
                                    'asset_code': _assetCodeCtrl.text.trim(),
                                    'name': _nameCtrl.text.trim(),
                                    'category': _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null,
                                    'description': _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
                                    'serial_number': _serialNumberCtrl.text.trim().isNotEmpty ? _serialNumberCtrl.text.trim() : null,
                                    'model': _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : null,
                                    'purchase_date': _purchaseDate,
                                    'purchase_price': double.tryParse(_purchasePriceCtrl.text),
                                    'current_value': double.tryParse(_currentValueCtrl.text),
                                    'depreciation_months': int.tryParse(_depreciationMonthsCtrl.text),
                                    'warranty_expiry_date': _warrantyExpiryDate,
                                    'condition': _selectedCondition,
                                    'notes': _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                                  };
                                  
                                  if (asset != null) {
                                    await repo.updateAsset(asset.id, data);
                                  } else {
                                    await repo.createAsset(data);
                                  }
                                  ref.invalidate(assetsProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(asset != null ? 'Asset updated successfully' : 'Asset created successfully'), backgroundColor: AppColors.success));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                                }
                              },
                              child: Text(asset != null ? 'Save Changes' : 'Create Asset', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.grey600, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.grey400),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _showAssignDialog(AssetData asset) {
    _resetForm();
    _selectedEmployee = null;

    bool isFetching = true;
    List<Map<String, dynamic>> sheetEmployees = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (isFetching && sheetEmployees.isEmpty) {
            AdminOperationsRepository().getEmployees().then((data) {
              if (ctx.mounted) {
                setSheetState(() {
                  sheetEmployees = data;
                  isFetching = false;
                });
              }
            }).catchError((_) {
              if (ctx.mounted) {
                setSheetState(() {
                  sheetEmployees = [];
                  isFetching = false;
                });
              }
            });
          }
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Assign Asset', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                        SizedBox(height: 4),
                        Text('Transfer asset to an employee', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                      ]),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.grey500), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Asset info preview card (Glassmorphism inspired)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.primary.withAlpha(20), AppColors.primary.withAlpha(5)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withAlpha(30)),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))]),
                              child: Icon(_categoryIcon(asset.category), color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey900)),
                                const SizedBox(height: 2),
                                Text(asset.assetCode, style: TextStyle(fontSize: 13, color: AppColors.grey500, fontFamily: 'monospace')),
                              ]),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        // Employee dropdown
                        isFetching
                            ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                            : sheetEmployees.isEmpty
                                ? const Padding(padding: EdgeInsets.all(20), child: Text('No employees found', style: TextStyle(color: AppColors.grey500)))
                                : DropdownButtonFormField<Map<String, dynamic>>(
                                    initialValue: _selectedEmployee,
                                    decoration: InputDecoration(
                                      labelText: 'Assign To Employee *',
                                      labelStyle: const TextStyle(color: AppColors.grey600),
                                      filled: true,
                                      fillColor: AppColors.grey50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    dropdownColor: Colors.white,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey500),
                                    items: sheetEmployees.map((e) {
                                      final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                                      final id = e['employee_id'] ?? e['id'] ?? '';
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: e,
                                        child: Text('$name ($id)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setSheetState(() => _selectedEmployee = v),
                                  ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _conditionAtAssignmentCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Condition at Assignment',
                            hintText: 'Note any scratches or damage...',
                            labelStyle: const TextStyle(color: AppColors.grey600),
                            hintStyle: const TextStyle(color: AppColors.grey400),
                            filled: true,
                            fillColor: AppColors.grey50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primary.withAlpha(100),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (_selectedEmployee == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee'), backgroundColor: AppColors.danger));
                                return;
                              }
                              try {
                                final employeeId = _selectedEmployee!['id'] as int;
                                await AssetsRepository().assignAsset(
                                  asset.id,
                                  employeeId,
                                  conditionAtAssignment: _conditionAtAssignmentCtrl.text.trim().isNotEmpty ? _conditionAtAssignmentCtrl.text.trim() : null,
                                );
                                ref.invalidate(assetsProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Asset assigned successfully'), backgroundColor: AppColors.success));
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                              }
                            },
                            child: const Text('Confirm Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHistory(AssetData asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssetHistorySheet(assetId: asset.id, assetName: asset.name),
    );
  }

  Future<void> _deleteAsset(AssetData asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Delete "${asset.name}" (${asset.assetCode})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AssetsRepository().deleteAsset(asset.id);
        ref.invalidate(assetsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset deleted'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _returnAsset(AssetData asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return Asset'),
        content: Text('Mark "${asset.name}" as returned?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Return')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await AssetsRepository().returnAsset(asset.id);
        ref.invalidate(assetsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset returned'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Company Assets', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: assetsAsync.when(
        data: (items) {
          // Compute summary stats
          final totalAssets = items.length;
          final assignedAssets = items.where((a) => a.status == 'assigned').length;
          final availableAssets = items.where((a) => a.status == 'available').length;
          final totalValue = items.fold<double>(0, (sum, a) => sum + a.displayValue);

          return items.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.grey200),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
                          child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.grey400),
                        ),
                        const SizedBox(height: 16),
                        const Text('No assets found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.grey800)),
                        const SizedBox(height: 8),
                        const Text('Add your first company asset to get started', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateEditDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Asset', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ── Summary cards ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 400;
                          return Column(
                            children: [
                              Row(children: [
                                Expanded(child: _summaryCard(Icons.inventory_2, Colors.indigo, totalAssets.toString(), 'Total Assets')),
                                if (wide) const SizedBox(width: 10),
                                if (wide) Expanded(child: _summaryCard(Icons.person, AppColors.info, assignedAssets.toString(), 'Assigned')),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: _summaryCard(Icons.laptop, AppColors.success, availableAssets.toString(), 'Available')),
                                if (wide) const SizedBox(width: 10),
                                if (wide) Expanded(child: _summaryCard(Icons.attach_money, Colors.orange, '\$${totalValue.toStringAsFixed(totalValue == totalValue.roundToDouble() ? 0 : 2)}', 'Total Value')),
                              ]),
                            ],
                          );
                        },
                      ),
                    ),
                    // ── Asset grid/cards ──────────────────────────────
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth <= 600) {
                            return ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _buildAssetCard(items[i]),
                            );
                          }
                          // Grid layout for tablet using chunked ListView to prevent vertical overflow
                          return ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: (items.length / 2).ceil(),
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final firstItem = items[i * 2];
                              final hasSecond = i * 2 + 1 < items.length;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildAssetCard(firstItem)),
                                  const SizedBox(width: 14),
                                  if (hasSecond) Expanded(child: _buildAssetCard(items[i * 2 + 1])) else Expanded(child: const SizedBox()),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
        },
        loading: () => const LoadingIndicator(message: 'Loading assets...'),
        error: (e, _) => Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(assetsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _summaryCard(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.grey500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAssetCard(AssetData asset) {
    // Warranty warnings
    final now = DateTime.now();
    bool isWarrantyExpiring = false;
    bool isWarrantyExpired = false;
    if (asset.warrantyExpiryDate != null) {
      try {
        final warrantyDate = DateTime.parse(asset.warrantyExpiryDate!);
        isWarrantyExpired = warrantyDate.isBefore(now);
        isWarrantyExpiring = !isWarrantyExpired && warrantyDate.difference(now).inDays < 30;
      } catch (_) {}
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon, name, status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey100)),
                      child: Icon(_categoryIcon(asset.category), color: AppColors.grey600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(asset.assetCode, style: TextStyle(fontSize: 12, color: AppColors.grey500, fontFamily: 'monospace')),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                    _buildStatusBadge(asset.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Condition', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                    _buildConditionBadge(asset.condition),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Value', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                    Text(
                      '\$${asset.displayValue.toStringAsFixed(asset.displayValue == asset.displayValue.roundToDouble() ? 0 : 2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900),
                    ),
                  ],
                ),
                if (asset.assignedTo != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.person, size: 14, color: AppColors.grey400),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Assigned to: ${asset.assignedTo!}', style: TextStyle(fontSize: 12, color: AppColors.grey600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
                // Warranty warning
                if (isWarrantyExpired || isWarrantyExpiring) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isWarrantyExpired ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isWarrantyExpired ? Colors.red.shade100 : Colors.orange.shade100),
                    ),
                    child: Row(children: [
                      Icon(Icons.shield, size: 16, color: isWarrantyExpired ? AppColors.danger : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isWarrantyExpired ? 'Warranty Expired' : 'Warranty Expiring Soon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isWarrantyExpired ? Colors.red.shade700 : Colors.orange.shade700)),
                          Text(asset.warrantyExpiryDate!, style: TextStyle(fontSize: 11, color: isWarrantyExpired ? Colors.red.shade600 : Colors.orange.shade600)),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          // Action buttons footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey50.withAlpha(128),
              border: const Border(top: BorderSide(color: AppColors.grey100)),
            ),
            child: Row(
              children: [
                if (asset.status == 'available')
                  InkWell(
                    onTap: () => _showAssignDialog(asset),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.person_add, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      ]),
                    ),
                  ),
                if (asset.status == 'assigned')
                  InkWell(
                    onTap: () => _returnAsset(asset),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.keyboard_return, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text('Return', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                      ]),
                    ),
                  ),
                const Spacer(),
                _actionButton(Icons.edit, AppColors.primary, () => _showCreateEditDialog(asset: asset)),
                const SizedBox(width: 8),
                _actionButton(Icons.history, AppColors.grey600, () => _showHistory(asset)),
                const SizedBox(width: 8),
                _actionButton(Icons.delete_outline, AppColors.danger, () => _deleteAsset(asset)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Asset History Bottom Sheet ──────────────────────────────────────────────
class _AssetHistorySheet extends StatefulWidget {
  final int assetId;
  final String assetName;
  const _AssetHistorySheet({required this.assetId, required this.assetName});

  @override
  State<_AssetHistorySheet> createState() => _AssetHistorySheetState();
}

class _AssetHistorySheetState extends State<_AssetHistorySheet> {
  bool _isLoading = true;
  List<AssetAssignmentData> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await AssetsRepository().getAssetHistory(widget.assetId);
      setState(() { _history = history; _isLoading = false; });
    } catch (_) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Assignment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                    const SizedBox(height: 2),
                    Text(widget.assetName, style: TextStyle(fontSize: 13, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.grey200),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading history...')
                : _history.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 48, color: AppColors.grey300),
                          const SizedBox(height: 12),
                          const Text('No assignment history', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                          const SizedBox(height: 4),
                          const Text('This asset has never been assigned to anyone.', style: TextStyle(fontSize: 12, color: AppColors.grey400)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: _history.length,
                        itemBuilder: (context, i) {
                          final h = _history[i];
                          final isLast = i == _history.length - 1;
                          final isReturned = h.returnedDate != null;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Timeline line and icon
                                Column(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isReturned ? AppColors.grey100 : AppColors.success.withAlpha(26),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isReturned ? Icons.keyboard_return : Icons.check_circle,
                                        size: 16,
                                        color: isReturned ? AppColors.grey500 : AppColors.success,
                                      ),
                                    ),
                                    if (!isLast) Expanded(child: Container(width: 2, color: AppColors.grey200, margin: const EdgeInsets.symmetric(vertical: 4))),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 14, color: AppColors.grey400),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                h.employeeName,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey900),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isReturned ? AppColors.grey100 : AppColors.success.withAlpha(20),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isReturned ? 'Returned' : 'Active',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isReturned ? AppColors.grey600 : AppColors.success,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calendar_today, size: 12, color: AppColors.grey500),
                                                const SizedBox(width: 4),
                                                Text('Assigned: ${h.assignedDate}', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                              ],
                                            ),
                                            if (isReturned)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.keyboard_return, size: 12, color: AppColors.grey500),
                                                  const SizedBox(width: 4),
                                                  Text('Returned: ${h.returnedDate}', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                                ],
                                              ),
                                          ],
                                        ),
                                        if (h.notes != null && h.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text('Notes: ${h.notes}', style: TextStyle(fontSize: 11, color: AppColors.grey500, fontStyle: FontStyle.italic)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}