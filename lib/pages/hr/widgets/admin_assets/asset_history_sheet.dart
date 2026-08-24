import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/services/assets_repository.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_assets/asset_shared_widgets.dart';

class AssetHistorySheet extends StatefulWidget {
  final int assetId;
  final String assetName;

  const AssetHistorySheet({
    super.key,
    required this.assetId,
    required this.assetName,
  });

  static void show({
    required BuildContext context,
    required int assetId,
    required String assetName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetHistorySheet(
        assetId: assetId,
        assetName: assetName,
      ),
    );
  }

  @override
  State<AssetHistorySheet> createState() => _AssetHistorySheetState();
}

class _AssetHistorySheetState extends State<AssetHistorySheet> {
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
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.assignmentHistoryTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.assetName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grey200),
            Expanded(
              child: _isLoading
                  ? const LoadingIndicator(message: 'Loading history...')
                  : _history.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 48,
                              color: AppColors.grey300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noAssignmentHistory,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.noAssignmentHistoryDesc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
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
                                          color: isReturned
                                              ? AppColors.grey100
                                              : AppColors.success.withAlpha(26),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isReturned
                                              ? Icons.keyboard_return_rounded
                                              : Icons.check_circle_rounded,
                                          size: 16,
                                          color: isReturned
                                              ? AppColors.grey500
                                              : AppColors.success,
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: AppColors.grey200,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.grey50,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.border(context),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                AssetSharedWidgets.buildEmployeeAvatar(
                                                  photoUrl: h.employeePhoto,
                                                  name: h.employeeName,
                                                  size: 34,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        h.employeeName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 14,
                                                          color:
                                                              AppColors.textPrimary(
                                                            context,
                                                          ),
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                      if (h.employeeKhmerName !=
                                                              null &&
                                                          h.employeeKhmerName!
                                                              .isNotEmpty)
                                                        Text(
                                                          h.employeeKhmerName!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                AppColors.grey600,
                                                          ),
                                                        ),
                                                      if (h.employeePosition !=
                                                              null &&
                                                          h.employeePosition!
                                                              .isNotEmpty)
                                                        Text(
                                                          h.employeePosition!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10.5,
                                                            color:
                                                                AppColors.grey500,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isReturned
                                                        ? AppColors.grey200
                                                        : AppColors.success
                                                            .withAlpha(25),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isReturned
                                                        ? 'Returned'
                                                        : 'Active',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isReturned
                                                          ? AppColors.grey700
                                                          : AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            const Divider(
                                              height: 1,
                                              color: AppColors.grey200,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today_rounded,
                                                      size: 12,
                                                      color: AppColors.grey500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l10n.assignedDateLabel(
                                                        h.assignedDate,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.grey600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (isReturned)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.keyboard_return_rounded,
                                                        size: 12,
                                                        color: AppColors.grey500,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        l10n.returnedDateLabel(
                                                          h.returnedDate!,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              AppColors.grey600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            if (h.conditionAtAssignment !=
                                                    null ||
                                                h.conditionAtReturn != null) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  if (h.conditionAtAssignment !=
                                                      null) ...[
                                                    Text(
                                                      'Condition at assign: ${h.conditionAtAssignment}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.grey600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                  if (h.conditionAtReturn !=
                                                      null) ...[
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'Returned condition: ${h.conditionAtReturn}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.grey600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                            if (h.notes != null &&
                                                h.notes!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                l10n.notesLabel(h.notes!),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.grey600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
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
            ),
          ],
        ),
      ),
    );
  }
}
