import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
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
  List<Map<String, dynamic>> _employees = [];
  bool _loadingEmployees = false;
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

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final repo = AdminOperationsRepository();
      _employees = await repo.getEmployees();
    } catch (_) {
      _employees = [];
    }
    setState(() => _loadingEmployees = false);
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(asset != null ? 'Edit Asset' : 'Add New Asset', style: const TextStyle(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildTextField(_assetCodeCtrl, 'Asset Code *', hint: 'e.g. AST-001'),
                    const SizedBox(height: 10),
                    _buildTextField(_nameCtrl, 'Name *', hint: 'e.g. MacBook Pro M3'),
                    const SizedBox(height: 10),
                    _buildTextField(_categoryCtrl, 'Category', hint: 'e.g. Laptop, Phone, Furniture'),
                    const SizedBox(height: 10),
                    _buildTextField(_descriptionCtrl, 'Description', maxLines: 2),
                    const SizedBox(height: 10),
                    _buildTextField(_serialNumberCtrl, 'Serial Number'),
                    const SizedBox(height: 10),
                    _buildTextField(_modelCtrl, 'Model', hint: 'e.g. A2991'),
                    const SizedBox(height: 10),
                    // Condition dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('New')),
                        DropdownMenuItem(value: 'good', child: Text('Good')),
                        DropdownMenuItem(value: 'fair', child: Text('Fair')),
                        DropdownMenuItem(value: 'poor', child: Text('Poor')),
                        DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                      ],
                      onChanged: (v) => setDialogState(() => _selectedCondition = v ?? 'new'),
                    ),
                    const SizedBox(height: 10),
                    // Purchase date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (date != null) setDialogState(() => _purchaseDate = date.toIso8601String().substring(0, 10));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Purchase Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(_purchaseDate ?? 'Select date...', style: TextStyle(color: _purchaseDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_purchasePriceCtrl, 'Purchase Price (\$)', keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _buildTextField(_currentValueCtrl, 'Manual Current Value (\$)', keyboardType: TextInputType.number, hint: 'Leave empty for auto depreciation'),
                    const SizedBox(height: 10),
                    _buildTextField(_depreciationMonthsCtrl, 'Depreciation (Months)', keyboardType: TextInputType.number, hint: 'e.g. 36 for 3 years'),
                    const SizedBox(height: 10),
                    // Warranty date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (date != null) setDialogState(() => _warrantyExpiryDate = date.toIso8601String().substring(0, 10));
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Warranty Expiry Date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Text(_warrantyExpiryDate ?? 'Select date...', style: TextStyle(color: _warrantyExpiryDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_notesCtrl, 'Internal Notes', maxLines: 2),
                  ]),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _resetForm();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (_assetCodeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) return;
                  try {
                    final repo = AdminOperationsRepository();
                    if (asset != null) {
                      await repo.updateAsset(asset.id,
                        assetCode: _assetCodeCtrl.text.trim(),
                        name: _nameCtrl.text.trim(),
                        category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null,
                        description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
                        serialNumber: _serialNumberCtrl.text.trim().isNotEmpty ? _serialNumberCtrl.text.trim() : null,
                        model: _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : null,
                        purchaseDate: _purchaseDate,
                        purchasePrice: double.tryParse(_purchasePriceCtrl.text),
                        currentValue: double.tryParse(_currentValueCtrl.text),
                        depreciationMonths: int.tryParse(_depreciationMonthsCtrl.text),
                        warrantyExpiryDate: _warrantyExpiryDate,
                        condition: _selectedCondition,
                        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                      );
                    } else {
                      await repo.createAsset(
                        assetCode: _assetCodeCtrl.text.trim(),
                        name: _nameCtrl.text.trim(),
                        category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null,
                        description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
                        serialNumber: _serialNumberCtrl.text.trim().isNotEmpty ? _serialNumberCtrl.text.trim() : null,
                        model: _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : null,
                        purchaseDate: _purchaseDate,
                        purchasePrice: double.tryParse(_purchasePriceCtrl.text),
                        currentValue: double.tryParse(_currentValueCtrl.text),
                        depreciationMonths: int.tryParse(_depreciationMonthsCtrl.text),
                        warrantyExpiryDate: _warrantyExpiryDate,
                        condition: _selectedCondition,
                        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                      );
                    }
                    ref.invalidate(assetsProvider);
                    _resetForm();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(asset != null ? 'Asset updated' : 'Asset created'), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
                  }
                },
                child: Text(asset != null ? 'Update Asset' : 'Create Asset'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignDialog(AssetData asset) {
    _resetForm();
    _loadEmployees();
    _selectedEmployee = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Asset', style: TextStyle(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Asset info preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey200)),
                    child: Row(children: [
                      Icon(_categoryIcon(asset.category), color: AppColors.grey600, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(asset.assetCode, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  // Employee dropdown
                  _loadingEmployees
                      ? const Center(child: CircularProgressIndicator())
                      : _employees.isEmpty
                          ? Text('No employees loaded', style: TextStyle(color: AppColors.grey500))
                          : DropdownButtonFormField<Map<String, dynamic>>(
                              initialValue: _selectedEmployee,
                              decoration: const InputDecoration(
                                labelText: 'Assign To Employee *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _employees.map((e) {
                                final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                                final id = e['employee_id'] ?? e['id'] ?? '';
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: e,
                                  child: Text('$name ($id)', style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (v) => setDialogState(() => _selectedEmployee = v),
                            ),
                  const SizedBox(height: 10),
                  _buildTextField(_conditionAtAssignmentCtrl, 'Condition at Assignment', maxLines: 2, hint: 'Note any scratches or damage...'),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (_selectedEmployee == null) return;
                  try {
                    final employeeId = _selectedEmployee!['id'] as int;
                    await AdminOperationsRepository().assignAsset(
                      asset.id,
                      employeeId,
                      conditionAtAssignment: _conditionAtAssignmentCtrl.text.trim().isNotEmpty ? _conditionAtAssignmentCtrl.text.trim() : null,
                    );
                    ref.invalidate(assetsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset assigned'), backgroundColor: AppColors.success));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
                  }
                },
                child: const Text('Confirm Assignment'),
              ),
            ],
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
        await AdminOperationsRepository().deleteAsset(asset.id);
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
        await AdminOperationsRepository().returnAsset(asset.id);
        ref.invalidate(assetsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset returned'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.danger));
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.grey400, fontSize: 12),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
    );
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
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateEditDialog(),
            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
            label: const Text('Add Asset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
        ],
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2, size: 64, color: AppColors.grey300),
                    const SizedBox(height: 12),
                    const Text('No assets found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                    const SizedBox(height: 4),
                    const Text('Add your first company asset to get started', style: TextStyle(fontSize: 13, color: AppColors.grey400)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Asset'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                  ]),
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
                          final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.all(14),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: crossAxisCount == 2 ? 1.15 : 2.2,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) => _buildAssetCard(items[i]),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon, name, status
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)),
                child: Icon(_categoryIcon(asset.category), color: AppColors.grey600, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(asset.assetCode, style: TextStyle(fontSize: 11, color: AppColors.grey400, fontFamily: 'monospace')),
                ]),
              ),
              _buildStatusBadge(asset.status),
            ],
          ),
          const SizedBox(height: 10),
          // Details row
          Row(children: [
            const Text('Condition', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
            const Spacer(),
            _buildConditionBadge(asset.condition),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Value', style: TextStyle(fontSize: 11, color: AppColors.grey500)),
            const Spacer(),
            Text(
              '\$${asset.displayValue.toStringAsFixed(asset.displayValue == asset.displayValue.roundToDouble() ? 0 : 2)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ]),
          if (asset.assignedTo != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person, size: 14, color: AppColors.grey400),
              const SizedBox(width: 4),
              Expanded(child: Text(asset.assignedTo!, style: TextStyle(fontSize: 11, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          // Warranty warning
          if (isWarrantyExpired || isWarrantyExpiring) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWarrantyExpired ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isWarrantyExpired ? Colors.red.shade200 : Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(Icons.shield, size: 14, color: isWarrantyExpired ? AppColors.danger : Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isWarrantyExpired ? 'Warranty Expired' : 'Warranty Expiring Soon', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isWarrantyExpired ? AppColors.danger : Colors.orange.shade800)),
                    Text(asset.warrantyExpiryDate!, style: TextStyle(fontSize: 10, color: isWarrantyExpired ? Colors.red.shade400 : Colors.orange.shade600)),
                  ]),
                ),
              ]),
            ),
          ],
          const Spacer(),
          // Action buttons row
          Row(
            children: [
              if (asset.status == 'available')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignDialog(asset),
                    icon: const Icon(Icons.person_add, size: 14),
                    label: const Text('Assign', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success.withAlpha(102)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (asset.status == 'assigned')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _returnAsset(asset),
                    icon: const Icon(Icons.keyboard_return, size: 14),
                    label: const Text('Return', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info.withAlpha(102)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              const Spacer(),
              _actionButton(Icons.history, AppColors.info, () => _showHistory(asset)),
              const SizedBox(width: 4),
              _actionButton(Icons.edit, AppColors.primary, () => _showCreateEditDialog(asset: asset)),
              const SizedBox(width: 4),
              _actionButton(Icons.delete_outline, AppColors.danger, () => _deleteAsset(asset)),
            ],
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
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
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
      final history = await AdminOperationsRepository().getAssetHistory(widget.assetId);
      setState(() { _history = history; _isLoading = false; });
    } catch (_) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Assignment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                  Text(widget.assetName, style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                ]),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Loading history...')
                : _history.isEmpty
                    ? const Center(child: Text('No assignment history', style: TextStyle(color: AppColors.grey400)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final h = _history[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey200)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.person, size: 16, color: AppColors.grey500),
                                const SizedBox(width: 6),
                                Text(h.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ]),
                              const SizedBox(height: 4),
                              Text('Assigned: ${h.assignedDate}', style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                              if (h.returnedDate != null) Text('Returned: ${h.returnedDate}', style: TextStyle(fontSize: 12, color: AppColors.success)),
                              if (h.notes != null && h.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Condition: ${h.notes}', style: TextStyle(fontSize: 11, color: AppColors.grey500, fontStyle: FontStyle.italic)),
                              ],
                            ]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}