import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';
import 'package:mpg_hr_mobile_app/providers/admin_providers.dart';
import 'package:mpg_hr_mobile_app/services/admin_operations_repository.dart';
import 'package:mpg_hr_mobile_app/components/loading_indicator.dart';
import 'package:mpg_hr_mobile_app/services/network/dio_client.dart';
import 'package:mpg_hr_mobile_app/pages/hr/widgets/admin_leave/leave_shared_widgets.dart';

class LeaveBalancesTab extends ConsumerStatefulWidget {
  const LeaveBalancesTab({super.key});

  @override
  ConsumerState<LeaveBalancesTab> createState() => _LeaveBalancesTabState();
}

class _LeaveBalancesTabState extends ConsumerState<LeaveBalancesTab> {
  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(leaveBalancesProvider);

    return Stack(
      children: [
        balancesAsync.when(
          data: (items) => items.isEmpty
              ? LeaveEmptyPlaceholder(
                  icon: Icons.account_balance_wallet_rounded,
                  message: AppLocalizations.of(context)!.noLeaveBalances,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BalanceCard(balance: items[i]),
                  ),
                ),
          loading: () => LoadingIndicator(
            message: AppLocalizations.of(context)!.loadingBalances,
          ),
          error: (e, _) => LeaveErrorRetry(
            onRetry: () => ref.invalidate(leaveBalancesProvider),
          ),
        ),

        // FAB
        Positioned(
          right: 16,
          bottom: 20,
          child: LeaveGradientFAB(
            label: AppLocalizations.of(context)!.addBalance,
            icon: Icons.add_rounded,
            onPressed: () => _showAddBalanceSheet(context),
          ),
        ),
      ],
    );
  }

  void _showAddBalanceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => _AddBalanceSheet(
          scrollController: ctrl,
          onSaved: () => ref.invalidate(leaveBalancesProvider),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final LeaveBalanceData balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining =
        balance.allocatedDays + balance.carriedForward - balance.usedDays;
    final total = balance.allocatedDays > 0 ? balance.allocatedDays : 1;
    final pct = ((remaining / total) * 100).clamp(0, 100).toDouble();
    final barColor = pct > 50
        ? AppColors.success
        : pct > 20
        ? AppColors.warning
        : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    balance.employeeAvatar != null &&
                        balance.employeeAvatar!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: balance.employeeAvatar!.startsWith('http')
                              ? balance.employeeAvatar!
                              : '${DioClient.storageUrl}/${balance.employeeAvatar!.startsWith('/') ? balance.employeeAvatar!.substring(1) : balance.employeeAvatar!}',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          memCacheHeight: 120,
                          placeholder: (_, _) => const Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              balance.employeeName.isNotEmpty
                                  ? balance.employeeName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          balance.employeeName.isNotEmpty
                                ? balance.employeeName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.employeeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Row(
                      children: [
                        if (balance.employeeCode != null &&
                            balance.employeeCode!.isNotEmpty)
                          Text(
                            balance.employeeCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (balance.employeePosition != null &&
                            balance.employeePosition!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              balance.employeePosition!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${balance.leaveTypeName} · ${balance.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              GestureDetector(
                onTap: () => _editBalance(context, ref, balance),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _BalanceStat(
                label: AppLocalizations.of(context)!.allocated,
                value: balance.allocatedDays,
                color: AppColors.primary,
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.used,
                value: balance.usedDays,
                color: AppColors.warning,
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.carried,
                value: balance.carriedForward,
                color: const Color(0xFF8B5CF6),
              ),
              _BalanceStat(
                label: AppLocalizations.of(context)!.remaining,
                value: remaining,
                color: barColor,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.grey100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  void _editBalance(BuildContext context, WidgetRef ref, LeaveBalanceData b) {
    final allocCtrl = TextEditingController(text: b.allocatedDays.toString());
    final carriedCtrl = TextEditingController(
      text: b.carriedForward.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.editBalanceTitle(b.employeeName),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Text(
                b.leaveTypeName,
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LeaveSheetField(
                      controller: allocCtrl,
                      label: AppLocalizations.of(context)!.allocatedDays,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LeaveSheetField(
                      controller: carriedCtrl,
                      label: AppLocalizations.of(context)!.carriedForward,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                    try {
                      await ref
                          .read(adminOpsRepositoryProvider)
                          .updateLeaveBalance(b.id, {
                            'allocated_days':
                                double.tryParse(allocCtrl.text) ??
                                b.allocatedDays,
                            'carried_forward':
                                double.tryParse(carriedCtrl.text) ??
                                b.carriedForward,
                          });
                      ref.invalidate(leaveBalancesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.balanceUpdated,
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) Navigator.pop(ctx);
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
                    AppLocalizations.of(context)!.saveChanges,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _BalanceStat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value % 1 == 0
                ? value.toInt().toString()
                : value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBalanceSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onSaved;
  const _AddBalanceSheet({
    required this.scrollController,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddBalanceSheet> createState() => _AddBalanceSheetState();
}

class _AddBalanceSheetState extends ConsumerState<_AddBalanceSheet> {
  final _allocCtrl = TextEditingController(text: '12');
  final _carriedCtrl = TextEditingController(text: '0');
  int _year = DateTime.now().year;
  bool _loading = false;

  @override
  void dispose() {
    _allocCtrl.dispose();
    _carriedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final leaveTypesAsync = ref.watch(leaveTypesProvider);

    int? selectedEmpId;
    int? selectedTypeId;
    bool bulkMode = false;
    final List<int> selectedEmpIds = [];

    return Material(
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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.addLeaveBalance,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.addLeaveBalanceSubtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatefulBuilder(
                builder: (ctx, setSt) {
                  final l10n = AppLocalizations.of(ctx)!;
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single / Bulk mode toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSt(() => bulkMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !bulkMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.singleEmployee,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: !bulkMode
                                        ? AppColors.grey800
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSt(() => bulkMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bulkMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  l10n.multipleOrAllEmployees,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: bulkMode
                                        ? AppColors.grey800
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Employee picker
                    if (!bulkMode) ...[
                      Text(
                        AppLocalizations.of(context)!.employeeRequired,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      employeesAsync.when(
                        data: (emps) => DropdownButtonFormField<int>(
                          initialValue: selectedEmpId,
                          decoration: _dropDec(context),
                          hint: Text(
                            AppLocalizations.of(context)!.selectEmployee,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey400,
                            ),
                          ),
                          items: emps
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setSt(() => selectedEmpId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Text(l10n.failedToLoadEmployees),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.employeesRequired,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                          employeesAsync.maybeWhen(
                            data: (emps) => GestureDetector(
                              onTap: () => setSt(() {
                                if (selectedEmpIds.length == emps.length) {
                                  selectedEmpIds.clear();
                                } else {
                                  selectedEmpIds
                                    ..clear()
                                    ..addAll(emps.map((e) => e.id));
                                }
                              }),
                              child: Text(
                                emps.isNotEmpty &&
                                        selectedEmpIds.length == emps.length
                                    ? AppLocalizations.of(context)!.deselectAll
                                    : AppLocalizations.of(context)!.selectAll,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      employeesAsync.when(
                        data: (emps) => Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: emps.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppColors.grey100,
                            ),
                            itemBuilder: (_, i) {
                              final e = emps[i];
                              final checked = selectedEmpIds.contains(e.id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(
                                  e.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                activeColor: AppColors.primary,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (v) => setSt(() {
                                  if (v == true) {
                                    selectedEmpIds.add(e.id);
                                  } else {
                                    selectedEmpIds.remove(e.id);
                                  }
                                }),
                              );
                            },
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => Text(l10n.failedToLoadEmployees),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.employeesSelected(selectedEmpIds.length),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Leave type picker
                    Text(
                      AppLocalizations.of(context)!.leaveTypeRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    leaveTypesAsync.when(
                      data: (types) => DropdownButtonFormField<int>(
                        initialValue: selectedTypeId,
                        decoration: _dropDec(context),
                        hint: Text(
                          AppLocalizations.of(context)!.selectLeaveType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                        ),
                        items: types
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setSt(() => selectedTypeId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => Text(l10n.failedToLoadLeaveTypes),
                    ),
                    const SizedBox(height: 14),

                    // Year + Allocated row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.yearRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: _year.toString(),
                                keyboardType: TextInputType.number,
                                decoration: _dropDec(context),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (v) => setSt(
                                  () => _year = int.tryParse(v) ?? _year,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.allocatedDaysRequired,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              LeaveSheetField(
                                controller: _allocCtrl,
                                label: '',
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      AppLocalizations.of(context)!.carriedForward,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LeaveSheetField(
                      controller: _carriedCtrl,
                      label: '',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        onPressed:
                            (_loading ||
                                selectedTypeId == null ||
                                (!bulkMode && selectedEmpId == null) ||
                                (bulkMode && selectedEmpIds.isEmpty))
                            ? null
                            : () async {
                                setSt(() => _loading = true);
                                try {
                                  final allocatedDays =
                                      double.tryParse(_allocCtrl.text) ?? 12;
                                  final carriedForward =
                                      double.tryParse(_carriedCtrl.text) ?? 0;
                                  if (bulkMode) {
                                    await ref
                                        .read(adminOpsRepositoryProvider)
                                        .bulkAssignLeaveBalance(
                                          employeeIds: selectedEmpIds,
                                          leaveTypeId: selectedTypeId!,
                                          year: _year,
                                          allocatedDays: allocatedDays,
                                          carriedForward: carriedForward,
                                        );
                                  } else {
                                    await ref
                                        .read(adminOpsRepositoryProvider)
                                        .createLeaveBalance(
                                          employeeId: selectedEmpId!,
                                          leaveTypeId: selectedTypeId!,
                                          year: _year,
                                          allocatedDays: allocatedDays,
                                          carriedForward: carriedForward,
                                        );
                                  }
                                  widget.onSaved();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          bulkMode
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.leaveBalanceAssignedMulti(
                                                  selectedEmpIds.length,
                                                )
                                              : AppLocalizations.of(
                                                  context,
                                                )!.leaveBalanceCreated,
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                } finally {
                                  setSt(() => _loading = false);
                                }
                              },
                        child: _loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.textPrimary(context),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                bulkMode
                                    ? AppLocalizations.of(
                                        context,
                                      )!.assignToEmployees
                                    : AppLocalizations.of(context)!.addBalance,
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
  );
}

  InputDecoration _dropDec([BuildContext? context]) => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: context != null ? (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDarkElevated : AppColors.grey50) : AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context != null ? AppColors.border(context) : AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}
