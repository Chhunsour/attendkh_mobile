import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/services/assets_repository.dart';
import 'package:attendkh/utils/theme/theme.dart';

class AssetCreateEditSheet extends StatefulWidget {
  final AssetData? asset;
  final VoidCallback onSaved;

  const AssetCreateEditSheet({
    super.key,
    this.asset,
    required this.onSaved,
  });

  static void show({
    required BuildContext context,
    AssetData? asset,
    required VoidCallback onSaved,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetCreateEditSheet(
        asset: asset,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AssetCreateEditSheet> createState() => _AssetCreateEditSheetState();
}

class _AssetCreateEditSheetState extends State<AssetCreateEditSheet> {
  final _formKey = GlobalKey<FormState>();

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

  String _selectedCondition = 'new';
  String? _purchaseDate;
  String? _warrantyExpiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _populateFromAsset(widget.asset!);
    }
  }

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
    super.dispose();
  }

  void _populateFromAsset(AssetData asset) {
    _assetCodeCtrl.text = asset.assetCode;
    _nameCtrl.text = asset.name;
    _categoryCtrl.text = asset.category ?? '';
    _descriptionCtrl.text = asset.description ?? '';
    _serialNumberCtrl.text = asset.serialNumber ?? '';
    _modelCtrl.text = asset.model ?? '';
    _purchasePriceCtrl.text = asset.purchasePrice != null
        ? (asset.purchasePrice! % 1 == 0
            ? asset.purchasePrice!.toInt().toString()
            : asset.purchasePrice!.toString())
        : '';
    _currentValueCtrl.text = asset.currentValue != null
        ? (asset.currentValue! % 1 == 0
            ? asset.currentValue!.toInt().toString()
            : asset.currentValue!.toString())
        : '';
    _depreciationMonthsCtrl.text =
        asset.depreciationMonths != null && asset.depreciationMonths! > 0
            ? asset.depreciationMonths!.toString()
            : '';
    _notesCtrl.text = asset.notes ?? '';
    final cond = asset.condition.toLowerCase();
    _selectedCondition =
        ['new', 'good', 'fair', 'poor', 'damaged'].contains(cond)
            ? cond
            : 'new';
    _purchaseDate = asset.purchaseDate;
    _warrantyExpiryDate = asset.warrantyExpiryDate;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_assetCodeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.assetCodeAndNameRequired),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final categoryText = _categoryCtrl.text.trim();
    final category = categoryText.isNotEmpty ? categoryText : 'General';
    final depMonths = int.tryParse(_depreciationMonthsCtrl.text);

    setState(() => _isSubmitting = true);
    try {
      final repo = AssetsRepository();
      final data = {
        'asset_code': _assetCodeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'category': category,
        'description': _descriptionCtrl.text.trim().isNotEmpty
            ? _descriptionCtrl.text.trim()
            : null,
        'serial_number': _serialNumberCtrl.text.trim().isNotEmpty
            ? _serialNumberCtrl.text.trim()
            : null,
        'model': _modelCtrl.text.trim().isNotEmpty
            ? _modelCtrl.text.trim()
            : null,
        'purchase_date': _purchaseDate,
        'purchase_price': double.tryParse(_purchasePriceCtrl.text),
        'current_value': double.tryParse(_currentValueCtrl.text),
        'depreciation_months':
            (depMonths != null && depMonths > 0) ? depMonths : null,
        'warranty_expiry_date': _warrantyExpiryDate,
        'condition': _selectedCondition,
        'status': widget.asset?.status ?? 'available',
        'notes': _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : null,
      };

      if (widget.asset != null) {
        await repo.updateAsset(widget.asset!.id, data);
      } else {
        await repo.createAsset(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.asset != null
                  ? l10n.assetUpdatedSuccess
                  : l10n.assetCreatedSuccess,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
        height: MediaQuery.of(context).size.height * 0.85,
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset != null
                              ? l10n.editAssetTitle
                              : l10n.addNewAssetTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.fillInDetailsDesc,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        _buildSectionHeader(
                          l10n.basicDetailsTitle,
                          Icons.info_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _assetCodeCtrl,
                          l10n.assetCodeRequired,
                          'e.g. AST-001',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _nameCtrl,
                          l10n.nameRequired,
                          'e.g. MacBook Pro M3',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _categoryCtrl,
                                l10n.categoryLabel,
                                'Laptop, Phone...',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCondition,
                                decoration: InputDecoration(
                                  labelText: l10n.conditionLabel,
                                  labelStyle: const TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 14,
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
                                items: [
                                  DropdownMenuItem(
                                    value: 'new',
                                    child: Text(l10n.conditionNew),
                                  ),
                                  DropdownMenuItem(
                                    value: 'good',
                                    child: Text(l10n.conditionGood),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fair',
                                    child: Text(l10n.conditionFair),
                                  ),
                                  DropdownMenuItem(
                                    value: 'poor',
                                    child: Text(l10n.conditionPoor),
                                  ),
                                  DropdownMenuItem(
                                    value: 'damaged',
                                    child: Text(l10n.conditionDamaged),
                                  ),
                                ],
                                onChanged: (v) => setState(
                                  () => _selectedCondition = v ?? 'new',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _modelCtrl,
                                'Model',
                                'e.g. A2991',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _serialNumberCtrl,
                                'Serial Number',
                                '...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _descriptionCtrl,
                          'Description',
                          'Detailed specs...',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        // Financial Section
                        _buildSectionHeader(
                          l10n.financialDetailsTitle,
                          Icons.attach_money,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final initialDate = _purchaseDate != null
                                      ? (DateTime.tryParse(_purchaseDate!) ??
                                          DateTime.now())
                                      : DateTime.now();
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: AppColors.grey900,
                                          ),
                                          dialogTheme: DialogThemeData(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(
                                      () => _purchaseDate = date
                                          .toIso8601String()
                                          .substring(0, 10),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border(context),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.purchaseDateLabel,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _purchaseDate != null
                                                ? DateFormat('dd MMM yyyy')
                                                    .format(
                                                      DateTime.parse(
                                                        _purchaseDate!,
                                                      ),
                                                    )
                                                : 'Select date...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: _purchaseDate != null
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: _purchaseDate != null
                                                  ? AppColors.grey900
                                                  : AppColors.grey400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _purchasePriceCtrl,
                                l10n.purchasePriceLabel,
                                '\$',
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _currentValueCtrl,
                                l10n.currentValueLabel,
                                '\$',
                                isNumber: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _depreciationMonthsCtrl,
                                l10n.depreciationMonthsLabel,
                                'Months',
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Warranty & Notes Section
                        _buildSectionHeader(
                          l10n.additionalNotesTitle,
                          Icons.verified_user_outlined,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final initialDate = _warrantyExpiryDate != null
                                ? (DateTime.tryParse(_warrantyExpiryDate!) ??
                                    DateTime.now().add(
                                      const Duration(days: 365),
                                    ))
                                : DateTime.now().add(const Duration(days: 365));
                            final date = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: AppColors.grey900,
                                    ),
                                    dialogTheme: DialogThemeData(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(
                                () => _warrantyExpiryDate = date
                                    .toIso8601String()
                                    .substring(0, 10),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.warrantyExpiryLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _warrantyExpiryDate != null
                                          ? DateFormat('dd MMM yyyy').format(
                                              DateTime.parse(
                                                _warrantyExpiryDate!,
                                              ),
                                            )
                                          : 'Select date...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _warrantyExpiryDate != null
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: _warrantyExpiryDate != null
                                            ? AppColors.grey900
                                            : AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _notesCtrl,
                          'Internal Notes',
                          'Condition notes...',
                          maxLines: 2,
                        ),
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
                                    widget.asset != null
                                        ? l10n.saveChangesBtn
                                        : l10n.createAssetBtn,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.grey600, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.grey400),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
