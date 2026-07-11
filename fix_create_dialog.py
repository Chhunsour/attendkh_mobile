import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

old_dialog = r"  void _showCreateEditDialog\(\{AssetData\? asset\}\) \{[\s\S]*?^  \}"

new_dialog = """  void _showCreateEditDialog({AssetData? asset}) {
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
  }"""

content = re.sub(old_dialog, new_dialog, content, flags=re.MULTILINE)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)
print("done")
