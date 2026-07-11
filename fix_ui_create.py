import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

new_create_edit = """  void _showCreateEditDialog({AssetData? asset}) {
    _resetForm();
    if (asset != null) _populateFormFromAsset(asset);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
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
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(asset == null ? 'Add New Asset' : 'Edit Asset', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                        const SizedBox(height: 4),
                        Text(asset == null ? 'Register a new company asset' : 'Update asset details', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                      ]),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.grey500), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Section: Basic Info
                        const Text('BASIC INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        _buildTextField(_assetCodeCtrl, 'Asset Code *', hint: 'e.g. AST-001'),
                        const SizedBox(height: 16),
                        _buildTextField(_nameCtrl, 'Name *', hint: 'e.g. MacBook Pro M3'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_categoryCtrl, 'Category', hint: 'Laptop, Phone')),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCondition,
                                decoration: InputDecoration(
                                  labelText: 'Condition',
                                  labelStyle: const TextStyle(color: AppColors.grey600),
                                  filled: true,
                                  fillColor: AppColors.grey50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                dropdownColor: Colors.white,
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
                        _buildTextField(_descriptionCtrl, 'Description', maxLines: 2),
                        const SizedBox(height: 32),
                        
                        // Section: Identification
                        const Text('IDENTIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_serialNumberCtrl, 'Serial Number')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_modelCtrl, 'Model', hint: 'e.g. A2991')),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Section: Financial & Warranty
                        const Text('FINANCIAL & WARRANTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                        const SizedBox(height: 12),
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
                                    labelStyle: const TextStyle(color: AppColors.grey600),
                                    filled: true,
                                    fillColor: AppColors.grey50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  child: Text(_purchaseDate ?? 'Select date...', style: TextStyle(color: _purchaseDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2100));
                                  if (date != null) setSheetState(() => _warrantyExpiryDate = date.toIso8601String().substring(0, 10));
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Warranty Expiry',
                                    labelStyle: const TextStyle(color: AppColors.grey600),
                                    filled: true,
                                    fillColor: AppColors.grey50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  child: Text(_warrantyExpiryDate ?? 'Select date...', style: TextStyle(color: _warrantyExpiryDate != null ? AppColors.grey900 : AppColors.grey400, fontSize: 14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_purchasePriceCtrl, 'Purchase Price (\$)', keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_depreciationMonthsCtrl, 'Deprec. (Months)', keyboardType: TextInputType.number, hint: 'e.g. 36')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_currentValueCtrl, 'Manual Current Value (\$)', keyboardType: TextInputType.number, hint: 'Leave empty for auto depreciation'),
                        const SizedBox(height: 32),

                        // Section: Additional
                        const Text('ADDITIONAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        _buildTextField(_notesCtrl, 'Internal Notes', maxLines: 2),
                      ]),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.grey300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            _resetForm();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Cancel', style: TextStyle(color: AppColors.grey600, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              _resetForm();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(asset != null ? 'Asset updated' : 'Asset created'), backgroundColor: AppColors.success));
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
              ],
            ),
          );
        },
      ),
    );
  }"""

new_build_text_field = """  Widget _buildTextField(TextEditingController controller, String label, {String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.grey600),
        hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 13),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 15),
    );
  }"""

pattern1 = r"  void _showCreateEditDialog\(\{AssetData\? asset\}\) \{.*?                    ref\.invalidate\(assetsProvider\);\n                    _resetForm\(\);\n                    if \(ctx\.mounted\) Navigator\.pop\(ctx\);\n                    if \(mounted\) ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\(asset != null \? 'Asset updated' : 'Asset created'\), backgroundColor: AppColors\.success\)\);\n                  \} catch \(e\) \{\n                    if \(mounted\) ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content: Text\('\$e'\), backgroundColor: AppColors\.danger\)\);\n                  \}\n                \},\n                child: Text\(asset \!= null \? 'Save' : 'Create'\),\n              \),\n            \],\n          \);\n        \},\n      \),\n    \);\n  \}"
content = re.sub(pattern1, new_create_edit, content, flags=re.DOTALL)

pattern2 = r"  Widget _buildTextField\(TextEditingController controller, String label, \{String\? hint, int maxLines = 1, TextInputType keyboardType = TextInputType\.text\}\) \{.*?      style: const TextStyle\(fontSize: 14\),\n    \);\n  \}"
content = re.sub(pattern2, new_build_text_field, content, flags=re.DOTALL)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)

print("done")
