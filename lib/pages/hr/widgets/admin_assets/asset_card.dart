import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/assets_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_assets/asset_shared_widgets.dart';

class AssetCard extends StatelessWidget {
  final AssetData asset;
  final VoidCallback onAssign;
  final VoidCallback onReturn;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const AssetCard({
    super.key,
    required this.asset,
    required this.onAssign,
    required this.onReturn,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Warranty warnings
    final now = DateTime.now();
    bool isWarrantyExpiring = false;
    bool isWarrantyExpired = false;
    if (asset.warrantyExpiryDate != null) {
      try {
        final warrantyDate = DateTime.parse(asset.warrantyExpiryDate!);
        isWarrantyExpired = warrantyDate.isBefore(now);
        isWarrantyExpiring =
            !isWarrantyExpired && warrantyDate.difference(now).inDays < 30;
      } catch (_) {}
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon, name, code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey100),
                      ),
                      child: Icon(
                        AssetSharedWidgets.categoryIcon(asset.category),
                        color: AppColors.grey600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            asset.assetCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.statusLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                    AssetSharedWidgets.buildStatusBadge(asset.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.conditionLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                    AssetSharedWidgets.buildConditionBadge(asset.condition),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.valueLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                    Text(
                      '\$${asset.displayValue.toStringAsFixed(asset.displayValue == asset.displayValue.roundToDouble() ? 0 : 2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),

                // Assigned employee section
                if (asset.assignedTo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(25),
                      ),
                    ),
                    child: Row(
                      children: [
                        AssetSharedWidgets.buildEmployeeAvatar(
                          photoUrl: asset.assignedEmployeePhoto,
                          name: asset.assignedTo ?? '',
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      asset.assignedTo!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (asset.assignedEmployeeKhmerName != null &&
                                      asset.assignedEmployeeKhmerName!
                                          .isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '(${asset.assignedEmployeeKhmerName})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.grey500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (asset.assignedEmployeePosition != null ||
                                  asset.assignedDate != null)
                                Text(
                                  [
                                    if (asset.assignedEmployeePosition != null)
                                      asset.assignedEmployeePosition,
                                    if (asset.assignedDate != null)
                                      asset.assignedDate,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.grey500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Warranty warning
                if (isWarrantyExpired || isWarrantyExpiring) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isWarrantyExpired
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWarrantyExpired
                            ? Colors.red.shade100
                            : Colors.orange.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield,
                          size: 16,
                          color: isWarrantyExpired
                              ? AppColors.danger
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isWarrantyExpired
                                    ? l10n.warrantyExpired
                                    : l10n.warrantyExpiringSoon,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isWarrantyExpired
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                              Text(
                                asset.warrantyExpiryDate!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isWarrantyExpired
                                      ? Colors.red.shade600
                                      : Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                    onTap: onAssign,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.assignBtn,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (asset.status == 'assigned')
                  InkWell(
                    onTap: onReturn,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.keyboard_return,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.returnBtn,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                _actionButton(
                  Icons.edit,
                  AppColors.primary,
                  onEdit,
                ),
                const SizedBox(width: 8),
                _actionButton(
                  Icons.history,
                  AppColors.grey600,
                  onHistory,
                ),
                const SizedBox(width: 8),
                _actionButton(
                  Icons.delete_outline,
                  AppColors.danger,
                  onDelete,
                ),
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
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
