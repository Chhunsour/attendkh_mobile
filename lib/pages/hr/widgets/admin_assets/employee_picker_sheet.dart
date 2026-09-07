import 'package:attendkh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/pages/hr/widgets/admin_assets/asset_shared_widgets.dart';

class EmployeePickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final Map<String, dynamic>? currentSelected;
  final void Function(Map<String, dynamic>) onSelected;

  const EmployeePickerSheet({
    super.key,
    required this.employees,
    this.currentSelected,
    required this.onSelected,
  });

  static void show({
    required BuildContext context,
    required List<Map<String, dynamic>> employees,
    Map<String, dynamic>? currentSelected,
    required void Function(Map<String, dynamic>) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeePickerSheet(
        employees: employees,
        currentSelected: currentSelected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<EmployeePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _searchQuery.trim().toLowerCase();
    final filtered = widget.employees.where((e) {
      final fullName = (e['full_name'] as String? ??
              e['name'] as String? ??
              '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}')
          .trim()
          .toLowerCase();
      final khmerName = (e['khmer_name'] as String? ?? '').toLowerCase();
      final code = (e['employee_id'] as String? ?? '').toLowerCase();
      final pos = (e['position'] is Map
              ? (e['position']['name'] as String? ?? '')
              : (e['position'] as String? ?? ''))
          .toLowerCase();
      final dept = (e['department'] is Map
              ? (e['department']['name'] as String? ?? '')
              : (e['department'] as String? ?? ''))
          .toLowerCase();

      return query.isEmpty ||
          fullName.contains(query) ||
          khmerName.contains(query) ||
          code.contains(query) ||
          pos.contains(query) ||
          dept.contains(query);
    }).toList();

    return Material(
      color: AppColors.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectEmployee,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.chooseAssetRecipient,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: l10n.searchEmployeeHint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.grey400,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_search_rounded,
                            size: 44,
                            color: AppColors.grey300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noMatchingEmployeesFound,
                            style: const TextStyle(
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final emp = filtered[idx];
                        final name = (emp['full_name'] as String? ??
                                emp['name'] as String? ??
                                '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}')
                            .trim();
                        final khmerName = emp['khmer_name'] as String?;
                        final photo = emp['photo_url'] as String? ??
                            emp['avatar'] as String?;
                        final code = emp['employee_id'] as String? ??
                            emp['id']?.toString() ??
                            '';
                        String? position;
                        if (emp['position'] is Map) {
                          position = emp['position']['name'] as String?;
                        } else if (emp['position'] is String) {
                          position = emp['position'] as String?;
                        }

                        final isSelected =
                            widget.currentSelected?['id'] == emp['id'];

                        return InkWell(
                          onTap: () {
                            widget.onSelected(emp);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withAlpha(12)
                                  : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border(context),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                AssetSharedWidgets.buildEmployeeAvatar(
                                  photoUrl: photo,
                                  name: name,
                                  size: 42,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.textPrimary(
                                                  context,
                                                ),
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (code.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                code,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: AppColors.primary,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (khmerName != null &&
                                          khmerName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          khmerName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                      ],
                                      if (position != null &&
                                          position.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          position,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.grey400,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
