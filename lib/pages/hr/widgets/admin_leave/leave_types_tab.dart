import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendkh/l10n/app_localizations.dart';
import 'package:attendkh/utils/theme/theme.dart';
import 'package:attendkh/providers/admin_providers.dart';
import 'package:attendkh/services/admin_operations_repository.dart';
import 'package:attendkh/components/loading_indicator.dart';
import 'package:attendkh/pages/hr/widgets/admin_leave/leave_shared_widgets.dart';

class LeaveTypesTab extends ConsumerWidget {
  const LeaveTypesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(leaveTypesProvider);

    return Stack(
      children: [
        typesAsync.when(
          data: (items) => items.isEmpty
              ? LeaveEmptyPlaceholder(
                  icon: Icons.label_rounded,
                  message: AppLocalizations.of(context)!.noLeaveTypes,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LeaveTypeCard(
                      type: items[i],
                      onEdit: (t) => _showTypeSheet(context, ref, t),
                    ),
                  ),
                ),
          loading: () => LoadingIndicator(
            message: AppLocalizations.of(context)!.loadingTypes,
          ),
          error: (e, _) => LeaveErrorRetry(
            onRetry: () => ref.invalidate(leaveTypesProvider),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: LeaveGradientFAB(
            label: AppLocalizations.of(context)!.newType,
            icon: Icons.add_rounded,
            onPressed: () => _showTypeSheet(context, ref),
          ),
        ),
      ],
    );
  }

  void _showTypeSheet(
    BuildContext context,
    WidgetRef ref, [
    LeaveTypeData? type,
  ]) {
    final isEdit = type != null;
    final nameCtrl = TextEditingController(text: type?.name ?? '');
    final daysCtrl = TextEditingController(
      text: (type?.defaultDays ?? 12).toString(),
    );
    final codeCtrl = TextEditingController(text: type?.code ?? '');
    final noticeCtrl = TextEditingController(
      text: (type?.noticePeriodDays ?? 0).toString(),
    );
    final minTenureCtrl = TextEditingController(
      text: type?.minimumTenureDays?.toString() ?? '',
    );
    final maxConsecutiveCtrl = TextEditingController(
      text: type?.maxConsecutiveDays?.toString() ?? '',
    );
    final maxCarryForwardCtrl = TextEditingController(
      text: type?.maxCarryForward?.toString() ?? '',
    );
    final sortOrderCtrl = TextEditingController(
      text: (type?.sortOrder ?? 0).toString(),
    );

    bool isPaid = type?.isPaid ?? true;
    bool carryForward = type?.carryForward ?? false;
    bool requiresDocument = type?.requiresDocument ?? false;
    bool isActive = type?.isActive ?? true;
    bool isProrated = type?.isProrated ?? false;
    bool allowHalfDay = type?.allowHalfDay ?? false;
    String genderSpecific = type?.genderSpecific ?? 'all';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Material(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  isEdit
                      ? AppLocalizations.of(context)!.editLeaveType
                      : AppLocalizations.of(context)!.addLeaveType,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StatefulBuilder(
                    builder: (ctx2, setSt) {
                      String selectedColor = type?.color ?? '#f97316';
                      const colors = [
                        '#f97316',
                        '#3b82f6',
                        '#10b981',
                        '#ef4444',
                        '#8b5cf6',
                        '#ec4899',
                        '#14b8a6',
                        '#f59e0b',
                      ];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── General Information ──────────────────────────
                          Text(
                            AppLocalizations.of(context)!.generalInfo,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LeaveSheetField(
                            controller: nameCtrl,
                            label: AppLocalizations.of(
                              context,
                            )!.nameRequired,
                          ),
                          const SizedBox(height: 12),
                          LeaveSheetField(
                            controller: daysCtrl,
                            label: AppLocalizations.of(
                              context,
                            )!.daysPerYear,
                            keyboard:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.color,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (_, setColor) => Wrap(
                              spacing: 8,
                              children: colors.map((c) {
                                final col = leaveTypeColor(c);
                                final sel = selectedColor == c;
                                return GestureDetector(
                                  onTap: () =>
                                      setColor(() => selectedColor = c),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.grey800
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: sel
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: AppColors.textPrimary(
                                              context,
                                            ),
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Carry Forward ────────────────────────────────
                          CheckboxListTile(
                            value: carryForward,
                            onChanged: (v) =>
                                setSt(() => carryForward = v ?? false),
                            title: Text(
                              AppLocalizations.of(context)!.allowCarryForward,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          if (carryForward) ...[
                            const SizedBox(height: 4),
                            LeaveSheetField(
                              controller: maxCarryForwardCtrl,
                              label: AppLocalizations.of(
                                context,
                              )!.maxCarryForwardDays,
                              keyboard: TextInputType.number,
                            ),
                            const SizedBox(height: 8),
                          ],

                          const SizedBox(height: 16),

                          // ── Toggles ──────────────────────────────────────
                          Text(
                            AppLocalizations.of(context)!.options,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            value: isPaid,
                            onChanged: (v) => setSt(() => isPaid = v ?? true),
                            title: Text(
                              AppLocalizations.of(context)!.paidLeave,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          CheckboxListTile(
                            value: allowHalfDay,
                            onChanged: (v) =>
                                setSt(() => allowHalfDay = v ?? false),
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.allowHalfDayRequests,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          CheckboxListTile(
                            value: requiresDocument,
                            onChanged: (v) =>
                                setSt(() => requiresDocument = v ?? false),
                            title: Text(
                              AppLocalizations.of(context)!.requiresDocument,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                          ),
                          if (isEdit)
                            CheckboxListTile(
                              value: isActive,
                              onChanged: (v) =>
                                  setSt(() => isActive = v ?? true),
                              title: Text(
                                AppLocalizations.of(context)!.activeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.success,
                            ),

                          const SizedBox(height: 24),

                          // ── Save Button ──────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                try {
                                  final repo = ref.read(
                                    adminOpsRepositoryProvider,
                                  );
                                  if (isEdit) {
                                    await repo.updateLeaveType(type.id, {
                                      'name': nameCtrl.text.trim(),
                                      'code': codeCtrl.text.trim(),
                                      'days_per_year':
                                          double.tryParse(daysCtrl.text) ?? 12,
                                      'color': selectedColor,
                                      'is_paid': isPaid,
                                      'carry_forward': carryForward,
                                      'requires_document': requiresDocument,
                                      'is_active': isActive,
                                      'is_prorated': isProrated,
                                      'minimum_tenure_days':
                                          minTenureCtrl.text.isNotEmpty
                                          ? int.tryParse(minTenureCtrl.text)
                                          : null,
                                      'allow_half_day': allowHalfDay,
                                      'notice_period_days':
                                          int.tryParse(noticeCtrl.text) ?? 0,
                                      'max_consecutive_days':
                                          maxConsecutiveCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxConsecutiveCtrl.text,
                                            )
                                          : null,
                                      'sort_order':
                                          int.tryParse(sortOrderCtrl.text) ?? 0,
                                      'max_carry_forward':
                                          maxCarryForwardCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxCarryForwardCtrl.text,
                                            )
                                          : null,
                                      'gender_specific': genderSpecific,
                                    });
                                  } else {
                                    await repo.createLeaveType(
                                      name: nameCtrl.text.trim(),
                                      defaultDays:
                                          double.tryParse(daysCtrl.text) ?? 12,
                                      color: selectedColor,
                                      code: codeCtrl.text.trim(),
                                      isPaid: isPaid,
                                      carryForward: carryForward,
                                      requiresDocument: requiresDocument,
                                      isActive: isActive,
                                      isProrated: isProrated,
                                      minimumTenureDays:
                                          minTenureCtrl.text.isNotEmpty
                                          ? int.tryParse(minTenureCtrl.text)
                                          : null,
                                      allowHalfDay: allowHalfDay,
                                      noticePeriodDays:
                                          int.tryParse(noticeCtrl.text) ?? 0,
                                      maxConsecutiveDays:
                                          maxConsecutiveCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxConsecutiveCtrl.text,
                                            )
                                          : null,
                                      sortOrder:
                                          int.tryParse(sortOrderCtrl.text) ?? 0,
                                      maxCarryForward:
                                          maxCarryForwardCtrl.text.isNotEmpty
                                          ? int.tryParse(
                                              maxCarryForwardCtrl.text,
                                            )
                                          : null,
                                      genderSpecific: genderSpecific,
                                    );
                                  }
                                  ref.invalidate(leaveTypesProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.leaveTypeUpdated
                                              : AppLocalizations.of(
                                                  context,
                                                )!.leaveTypeCreated,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                isEdit
                                    ? AppLocalizations.of(context)!.saveChanges
                                    : AppLocalizations.of(context)!.create,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
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

class _LeaveTypeCard extends ConsumerWidget {
  final LeaveTypeData type;
  final void Function(LeaveTypeData) onEdit;
  const _LeaveTypeCard({required this.type, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = leaveTypeColor(type.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accent.withAlpha(18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      type.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                  if (type.code != null &&
                                      type.code!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(15),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: accent.withAlpha(40),
                                        ),
                                      ),
                                      child: Text(
                                        type.code!,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.daysPerYearLabel(
                                  type.defaultDays.toStringAsFixed(0),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: type.isActive
                                ? const Color(0xFFDCFCE7)
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.isActive
                                ? AppLocalizations.of(
                                    context,
                                  )!.activeLabel.toUpperCase()
                                : AppLocalizations.of(
                                    context,
                                  )!.inactiveLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: type.isActive
                                  ? AppColors.success
                                  : AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Policy badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LeavePolicyBadge(
                          label: type.isPaid
                              ? AppLocalizations.of(context)!.paid
                              : AppLocalizations.of(context)!.unpaid,
                          color: type.isPaid
                              ? AppColors.success
                              : AppColors.grey500,
                          bg: type.isPaid
                              ? const Color(0xFFDCFCE7)
                              : AppColors.grey100,
                        ),
                        if (type.isProrated)
                          const LeavePolicyBadge(
                            label: 'Prorated',
                            color: Color(0xFF2563EB),
                            bg: Color(0xFFDBEAFE),
                          ),
                        if (type.allowHalfDay)
                          LeavePolicyBadge(
                            label: AppLocalizations.of(context)!.halfDayBadge,
                            color: const Color(0xFF0F766E),
                            bg: const Color(0xFFCCFBF1),
                          ),
                        if (type.carryForward) ...[
                          LeavePolicyBadge(
                            label: type.maxCarryForward != null
                                ? AppLocalizations.of(
                                    context,
                                  )!.carryFwd(type.maxCarryForward!.toString())
                                : AppLocalizations.of(
                                    context,
                                  )!.carryForwardBadge,
                            color: const Color(0xFF7C3AED),
                            bg: const Color(0xFFF5F3FF),
                          ),
                        ],
                        if (type.maxConsecutiveDays != null)
                          LeavePolicyBadge(
                            label: AppLocalizations.of(
                              context,
                            )!.maxConsec(type.maxConsecutiveDays!.toString()),
                            color: const Color(0xFFB45309),
                            bg: const Color(0xFFFEF3C7),
                          ),
                        if (type.requiresDocument)
                          LeavePolicyBadge(
                            label: AppLocalizations.of(context)!.requiresDoc,
                            color: const Color(0xFFB45309),
                            bg: const Color(0xFFFEF3C7),
                          ),
                        if (type.genderSpecific != 'all')
                          LeavePolicyBadge(
                            label: AppLocalizations.of(context)!.genderBadge(
                              type.genderSpecific == 'male'
                                  ? AppLocalizations.of(context)!.maleOnly
                                  : AppLocalizations.of(context)!.femaleOnly,
                            ),
                            color: AppColors.grey600,
                            bg: AppColors.grey100,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Additional info row
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noticeSort(
                            type.noticePeriodDays.toString(),
                            type.sortOrder.toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey400,
                          ),
                        ),
                        if (type.minimumTenureDays != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.minTenureBadge(
                              type.minimumTenureDays!.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Footer: edit & delete
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => onEdit(type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.edit,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _confirmDelete(context, ref, type.id, type.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  size: 13,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  AppLocalizations.of(context)!.deleteLeaveType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(
                          context,
                        )!.deleteLeaveTypeConfirm(name),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppLocalizations.of(context)!.delete),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        await AdminOperationsRepository().deleteLeaveType(id);

        ref.invalidate(leaveTypesProvider);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.leaveTypeDeleted),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed: $e"),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
