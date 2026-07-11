import re

with open('lib/pages/hr/admin_assets_screen.dart', 'r') as f:
    content = f.read()

new_assign_dialog = """  void _showAssignDialog(AssetData asset) {
    _resetForm();
    _selectedEmployee = null;
    bool fetchStarted = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (!fetchStarted && _employees.isEmpty) {
            fetchStarted = true;
            _loadEmployees(setSheetState);
          }

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Assign Asset', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                        const SizedBox(height: 4),
                        Text('Select an employee to assign this asset', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
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
                        _loadingEmployees
                            ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                            : _employees.isEmpty
                                ? Padding(padding: const EdgeInsets.all(20), child: Text('No employees found', style: TextStyle(color: AppColors.grey500)))
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
                                    items: _employees.map((e) {
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
                                await AdminOperationsRepository().assignAsset(
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
  }"""

pattern = r"  void _showAssignDialog\(AssetData asset\) \{.*?      \),\n    \);\n  \}"
content = re.sub(pattern, new_assign_dialog, content, flags=re.DOTALL)

with open('lib/pages/hr/admin_assets_screen.dart', 'w') as f:
    f.write(content)

print("done")
